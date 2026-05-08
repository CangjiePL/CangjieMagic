/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */
package magic.utils.http

import magic.log.LogUtils
import magic.config.Config

import std.collection.{HashMap, contains}
import stdx.encoding.json.*
import std.collection.concurrent.BlockingQueue
import std.io.StringReader
import stdx.net.http.{
    Client as StdxHttpClient,
    ClientBuilder as StdxHttpClientBuilder,
    HttpRequest as StdxHttpRequest,
    HttpRequestBuilder as StdxHttpRequestBuilder,
    HttpResponse as StdxHttpResponse
}
import stdx.net.tls.TlsClientConfig
@When[ohos == "true"]
import ohos.net.http.*

//=====================================================================================

@When[ohos == "true"]
private func buildRequestOptions(method: String, header: HashMap<String, String>, body: Option<JsonObject>): HttpRequestOptions {
    let m = if (method == "POST") { RequestMethod.POST } else { RequestMethod.GET }
    if (let Some(b) <- body) {
        // Convert to string immediately to avoid potential thread-safety issues
        // with JsonObject in OHOS FFI callbacks
        let bodyStr = b.toJsonString()
        return HttpRequestOptions(
            method: m,
            extraData: HttpData.STRING_DATA(bodyStr),
            expectDataType: HttpDataType.STRING,
            header: header,
            readTimeout: UInt32(Config.httpReadWriteTimeout),
            connectTimeout: UInt32(Config.httpConnectTimeout),
        )
    } else {
        return HttpRequestOptions(
            method: m,
            expectDataType: HttpDataType.STRING,
            header: header,
            readTimeout: UInt32(Config.httpReadWriteTimeout),
            connectTimeout: UInt32(Config.httpConnectTimeout),
        )
    }
}

@When[ohos == "true"]
private func buildHybridHttpClient(url: String, verify: Bool): StdxHttpClient {
    let cb = StdxHttpClientBuilder()
    if (url.startsWith("https")) {
        var config = TlsClientConfig()
        if (!verify) {
            // Keep the default verifier for now. Some Cangjie 1.1.0 SDKs removed
            // the old TrustAll switch, and setting it here breaks compilation.
        }
        cb.tlsConfig(config)
    }
    return cb.build()
}

@When[ohos == "true"]
private func prepareHttpRequest(method: String,
                                url: String,
                                header: HashMap<String, String>,
                                body: Option<JsonObject>): StdxHttpRequest {
    let rb = StdxHttpRequestBuilder().url(url)
    if (let Some(b) <- body) {
        rb.body(b.toJsonString())
    }
    if (method == "POST") {
        rb.post()
    } else if (method == "GET") {
        rb.get()
    }
    for ((k, v) in header) {
        rb.header(k, v)
    }
    return rb.build()
}

@When[ohos == "true"]
private func sendHttp(method: String,
                      url: String,
                      header: HashMap<String, String>,
                      body: Option<JsonObject>,
                      verify: Bool): (StdxHttpClient, StdxHttpResponse) {
    let client = buildHybridHttpClient(url, verify)
    let req = prepareHttpRequest(method, url, header, body)
    try {
        return (client, client.send(req))
    } catch (ex: Exception) {
        client.close()
        LogUtils.error("Http ${url} with data: ${(body ?? JsonObject()).toJsonString()} failed")
        LogUtils.error("HTTP hybrid send failed: ${ex.message}")
        LogUtils.error(ex.toString())
        LogUtils.debug(ex)
        throw HttpException(ex.message)
    }
}

@When[ohos == "true"]
private func readHttpBody(resp: StdxHttpResponse): String {
    let reader = StringReader(resp.body)
    return reader.readToEnd()
}

@When[ohos == "true"]
protected struct HttpUtilsImpl {
    static protected func send(method: String,
                               url: String,
                               header: HashMap<String, String>,
                               body: Option<JsonObject>,
                               verify!: Bool): Option<String> {
        logHttpInfo(method, url, header, body, async: false)
        let httpRequest = createHttp()
        let httpOpt = buildRequestOptions(method, header, body)
        let queue = BlockingQueue<String>()
        httpRequest.request(
            url,
            { err, resp =>
                spawn {
                    if (let Some(e) <- err) {
                        LogUtils.error("Request failed. Exception: ${e.message}")
                        queue.enqueue("[ERROR_request]")
                    }
                    if (let Some(r) <- resp){
                        match (r.result) {
                            case STRING_DATA(value) => queue.enqueue(value)
                            case ARRAY_DATA(value) => queue.enqueue(String.fromUtf8(value))
                            case _ => throw UnsupportedException("Unsupported http response type")
                        }
                    }
                    httpRequest.destroy()
                }
            },
            options: httpOpt
        )
        // Receive the response content
        let msg = queue.dequeue()
        if (msg == "[ERROR_request]") {
            throw HttpException("Http request error")
        }
        LogUtils.trace("Raw http response: ${msg}")
        return msg
    }

    static protected func asyncSend(method: String,
                                    url: String,
                                    header: HashMap<String, String>,
                                    body: Option<JsonObject>,
                                    verify!: Bool): HttpStream {
        logHttpInfo(method, url, header, body, async: true)
        let httpRequest = createHttp()
        let httpStream = HttpStream(closeFn: { =>
            LogUtils.debug("Http stream closed ${url}")
            httpRequest.destroy()
        })
        // Register callbacks
        httpRequest.onDataReceive({ data: Array<Byte> =>
            // let str = String.fromUtf8(data)
            // LogUtils.debug("Receive http stream: ${str}")
            // Each line is a chunk response from chat models, so we split the data here
            // for (line in str.split("\n", removeEmpty: true)) {
                // httpStream.put(line)
            // }

            LogUtils.debug("Http stream received bytes from ${url}; size: ${data.size}")
            httpStream.put(data)
        })
        httpRequest.onDataEnd({ =>
            LogUtils.debug("End the http stream of ${url}")
            httpStream.markEOF()
            httpRequest.offDataReceive()
            httpRequest.offDataEnd()
            httpRequest.destroy()
        })
        // Make the request
        let httpOpt = buildRequestOptions(method, header, body)
        httpRequest.requestInStream(
            url,
            { err, code =>
                if (let Some(e) <- err) {
                    LogUtils.error("Http stream request for ${url} failed: ${e.message}")
                    httpStream.markError()
                    httpStream.markEOF()
                }
            },
            options: httpOpt
        )
        return httpStream
    }

    static protected func hybridSend(method: String,
                                     url: String,
                                     header: HashMap<String, String>,
                                     body: Option<JsonObject>,
                                     verify!: Bool): HttpResult {
        logHttpInfo(method, url, header, body, async: false)
        let (client, resp) = sendHttp(method, url, header, body, verify)
        if ((resp.headers.get("Content-Type") |> contains("text/event-stream")) ||
            (resp.headers.get("content-type") |> contains("text/event-stream"))) {
            let httpStream = HttpStream()
            spawn {
                processStream(client, resp, httpStream)
            }
            return HttpResult(
                status: Int64(resp.status),
                header: resp.headers,
                value: HttpResultOption.Stream(httpStream)
            )
        } else {
            return HttpResult(
                status: Int64(resp.status),
                header: resp.headers,
                value: HttpResultOption.Json(processJson(client, resp))
            )
        }
    }

    static private func processJson(client: StdxHttpClient, response: StdxHttpResponse): String {
        try {
            return readHttpBody(response)
        } finally {
            client.close()
        }
    }

    static private func processStream(client: StdxHttpClient, response: StdxHttpResponse, httpStream: HttpStream): Unit {
        try {
            let buffer = Array<Byte>(1024 * 10, { _ => 0 })
            while (true) {
                let length = response.body.read(buffer)
                if (length == 0) {
                    break
                }
                httpStream.put(buffer[..length].clone())
            }
            LogUtils.trace("End http stream. Status: ${response.status}")
            httpStream.markEOF()
        } catch (ex: Exception) {
            LogUtils.error("Http stream processing failed: ${ex.message}")
            httpStream.markError()
            httpStream.markEOF()
        } finally {
            client.close()
        }
    }
}
