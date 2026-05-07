/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2025. All rights reserved.
 */
package magic.utils.http

import magic.log.LogUtils
import magic.utils.{getEnv, sleep2}
import magic.config.Config

import std.collection.{HashMap, contains}
// @When[cjc_version < "1.0.0"]
// import std.socket.{SocketAddress, TcpSocket}
import std.net.{SocketAddress, TcpSocket}
import std.io.StringReader

import stdx.net.tls.TlsClientConfig
import stdx.net.http.*
import stdx.encoding.json.*
import stdx.encoding.url.URL

private func buildHttpClient(url: String, verify: Bool): Client {
    let cb = ClientBuilder()
    cb.readTimeout(Duration.minute * 10)
    if (url.startsWith("https")) {
        var config = TlsClientConfig()
        if (!verify) {
            // CertificateVerifyMode may have changed in 1.1.0, try without setting verifyMode
            // config.verifyMode = CertificateVerifyMode.TrustAll
        }
        // config.domain = URL.parse(url).hostName  // domain property may have been removed in 1.1.0
        cb.tlsConfig(config)
    }
    let TcpSocketConnector = { sa: SocketAddress =>
        let socket = TcpSocket(sa)
        socket.readTimeout = Duration.millisecond * Config.httpReadWriteTimeout
        socket.writeTimeout = Duration.millisecond * Config.httpReadWriteTimeout
        socket.connect(timeout: Duration.millisecond * Config.httpConnectTimeout)
        return socket
    }
    cb.connector(TcpSocketConnector)
    // if (let Some(proxy) <- getEnv("http_proxy")) {
    //     cb.httpProxy(proxy)
    // }
    // if (let Some(proxy) <- getEnv("https_proxy")) {
    //     cb.httpProxy(proxy)
    // }
    return cb.build()
}

private func prepareHttpRequest(method: String,
                                url: String,
                                header: HashMap<String, String>,
                                body: Option<JsonObject>): HttpRequest {
    let rb = HttpRequestBuilder().url(url)
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

private func sendHttp(method: String,
                      url: String,
                      header: HashMap<String, String>,
                      body: Option<JsonObject>,
                      verify: Bool): (Client, HttpResponse) {
    let client = buildHttpClient(url, verify)
    let req = prepareHttpRequest(method, url, header, body)
    try {
        let response = client.send(req)
        if (response.status != HttpStatusCode.STATUS_OK &&
            response.status != HttpStatusCode.STATUS_ACCEPTED) {
            let content = readHttpBody(response).trimAscii()
            let msg = if (content.isEmpty()) {
                "Http status: ${response.status}"
            } else {
                "Http status: ${response.status}\nHttp response: ${content}"
            }
            LogUtils.error("Http ${url} with data: ${(body ?? JsonObject()).toJsonString()} failed")
            LogUtils.error(msg)
            throw HttpException(msg)
        }
        return (client, response)
    } catch (ex: Exception) {
        LogUtils.error("Http ${url} with data: ${(body ?? JsonObject()).toJsonString()} failed")
        LogUtils.debug(ex)
        throw HttpException(ex.message)
    }
}

/**
 * Send HTTP request and return response with status code (without throwing exception)
 */
private func sendHttpWithStatus(method: String,
                                url: String,
                                header: HashMap<String, String>,
                                body: Option<JsonObject>,
                                verify: Bool): (Client, HttpResponse, Int64) {
    let client = buildHttpClient(url, verify)
    let req = prepareHttpRequest(method, url, header, body)
    try {
        let response = client.send(req)
        let status = Int64(response.status)
        return (client, response, status)
    } catch (ex: Exception) {
        client.close()
        LogUtils.error("Http ${url} with data: ${(body ?? JsonObject()).toJsonString()} failed")
        LogUtils.debug(ex)
        throw HttpException(ex.message)
    }
}

private func readHttpBody(resp: HttpResponse): String {
    let reader = StringReader(resp.body)
    return reader.readToEnd()
}

//=====================================================================================

@When[ohos != "true" && http != "curl"]
protected struct HttpUtilsImpl {
    /**
     * Check if the HTTP status code is retryable (429, 500, 503, 502, 504, 408)
     */
    static private func isRetryableStatus(status: Int64): Bool {
        return status == 429 || status == 500 || status == 503 || 
            status == 502 || status == 504 || status == 408
    }

    /**
     * Send HTTP request with exponential backoff retry for retryable status codes
     */
    static private func sendWithRetry(method: String,
                                      url: String,
                                      header: HashMap<String, String>,
                                      body: Option<JsonObject>,
                                      verify: Bool): Option<String> {
        let maxRetries: Int64 = 4
        let initialDelayMs: Int64 = 1000
        let multiplier: Int64 = 2
        for (attempt in 0..maxRetries) {
            let (client, resp, status) = sendHttpWithStatus(method, url, header, body, verify)
            // Check if status is retryable
            if (isRetryableStatus(status)) {
                if (attempt < maxRetries - 1) {
                    // Clean up current client
                    client.close()
                    // Calculate exponential backoff delay: initialDelayMs * (multiplier ^ attempt)
                    let delayMs = initialDelayMs * (multiplier ** UInt64(attempt))
                    LogUtils.debug(
                        "HttpUtilsImpl",
                        "Retryable status ${status} on attempt ${attempt + 1}/${maxRetries}. Retrying after ${delayMs}ms..."
                    )
                    sleep2(delayMs)
                    continue
                } else {
                    // Last attempt, log error and process (will throw exception)
                    LogUtils.error(
                        "HttpUtilsImpl",
                        "Retryable status ${status} exceeded after ${maxRetries} attempts. Giving up."
                    )
                    // Process response which will throw exception for non-200 status
                    let content = readHttpBody(resp).trimAscii()
                    let msg = if (content.isEmpty()) {
                        "Http status: ${status}"
                    } else {
                        "Http status: ${status}\nHttp response: ${content}"
                    }
                    client.close()
                    LogUtils.error("Http ${url} with data: ${(body ?? JsonObject()).toJsonString()} failed")
                    LogUtils.error(msg)
                    throw HttpException(msg)
                }
            } else {
                // Not retryable, process the response
                if (status != 200 && status != 202) {
                    // Non-retryable error, throw exception
                    let content = readHttpBody(resp).trimAscii()
                    let msg = if (content.isEmpty()) {
                        "Http status: ${status}"
                    } else {
                        "Http status: ${status}\nHttp response: ${content}"
                    }
                    client.close()
                    LogUtils.error("Http ${url} with data: ${(body ?? JsonObject()).toJsonString()} failed")
                    LogUtils.error(msg)
                    throw HttpException(msg)
                } else {
                    // Success, return response body
                    return processJson(client, resp)
                }
            }
        }
        // Should not reach here, but return None as fallback
        return None
    }

    static protected func send(method: String,
                               url: String,
                               header: HashMap<String, String>,
                               body: Option<JsonObject>,
                               verify!: Bool): Option<String> {
        // header.put("Accept", "application/json")
        logHttpInfo(method, url, header, body, async: false)
        // If retry is disabled, execute once and return
        if (!Config.enableHttpRetry) {
            let (client, resp) = sendHttp(method, url, header, body, verify)
            return processJson(client, resp)
        }
        // Retry logic enabled
        return sendWithRetry(method, url, header, body, verify)
    }

    static private func processJson(client: Client, response: HttpResponse): String {
        try {
            return readHttpBody(response)
        } finally {
            client.close()
        }
    }

    static protected func asyncSend(method: String,
                                    url: String,
                                    header: HashMap<String, String>,
                                    body: Option<JsonObject>,
                                    verify!: Bool): HttpStream {
        logHttpInfo(method, url, header, body, async: true)
        // header.add("Accept", "text/event-stream")
        let (client, resp) = sendHttp(method, url, header, body, verify)
        let httpStream = HttpStream()
        spawn {
            processStream(client, resp, httpStream)
        }
        return httpStream
    }

    static private func processStream(client: Client, response: HttpResponse, httpStream: HttpStream): Unit {
        let buffer = Array<Byte>(1024 * 10, { _ => 0})
        while (true) {
            let length = response.body.read(buffer)
            if (length == 0) {
                break
            } else {
                httpStream.put(buffer[..length].clone())
            }
        }
        // Put the termination mark
        LogUtils.trace("End http stream. Status: ${response.status}")
        httpStream.markEOF()
        client.close()
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
}