import std.process.*
import std.fs.*
import std.env.*

func getOsInfo() {
    @When[os == "Linux"]
    let os = "linux"

    @When[os == "Windows"]
    let os = "windows"

    @When[os == "macOS"]
    let os = "mac"

    @When[os != "Linux" && os != "Windows" && os != "macOS"]
    let os = "unknown"

    @When[arch == "aarch64"]
    let arch = "aarch64"

    @When[arch == "x86_64"]
    let arch = "x64"

    @When[arch != "x86_64" && arch != "aarch64"]
    let arch = "unknown"

    return (os, arch)
}

func downloadAndExtract(os: String, arch: String, isOhosTarget!: Bool = false): Int64 {
    let version = "1.1.0.1"
    let installDir = "./libs"
    
    // Determine platform name for URL
    // Windows: windows, Linux: linux, macOS: mac, OHOS: ohos
    // Check for OHOS by checking environment variable DEVECO_CANGJIE_HOME or target platform
    let devEcoHome = getVariable("DEVECO_CANGJIE_HOME")
    let target = getVariable("TARGET")
    let cjpmTarget = getVariable("CJPM_TARGET")
    let isOhos = isOhosTarget || devEcoHome.isSome() || 
                 (target.isSome() && (target.getOrThrow().contains("ohos") || target.getOrThrow().contains("OHOS"))) ||
                 (cjpmTarget.isSome() && (cjpmTarget.getOrThrow().contains("ohos") || cjpmTarget.getOrThrow().contains("OHOS")))
    
    // Determine platform name for URL
    // Priority: If OHOS target is detected, use "ohos" regardless of host OS
    // This handles cases where DevEco Studio runs on Windows/macOS but targets OHOS
    let platformName = if (isOhos) {
        "ohos"  // OHOS target detected, use OHOS stdx regardless of host OS
    } else if (os == "windows") {
        "windows"
    } else if (os == "linux") {
        "linux"
    } else if (os == "mac") {
        "mac"
    } else {
        // For unknown OS, check if it might be OHOS
        if (os.contains("ohos") || os.contains("OHOS")) {
            "ohos"
        } else {
            os  // Fallback to original os value
        }
    }
    
    let url = "https://gitcode.com/Cangjie/cangjie_stdx/releases/download/v${version}/cangjie-stdx-${platformName}-${arch}-${version}.zip"
    
    let targetDir = "${installDir}/cangjie-stdx-${platformName}-${arch}-${version}"
    let zipFile = "${installDir}/cangjie-stdx-${platformName}-${arch}-${version}.zip"

    // Check if stdx already exists (any 1.1.0 version)
    let installDirPath = Path(installDir)
    if (exists(installDirPath)) {
        Directory.walk(installDirPath) { fileInfo =>
            if (fileInfo.isDirectory() && fileInfo.path.fileName.startsWith("cangjie-stdx-${platformName}-${arch}-1.1.0")) {
                println("Found existing stdx dir: ${fileInfo.path.fileName}, skip downloading")
                return false  // Stop walking
            }
            return true  // Continue walking
        }
    }

    // create target directory
    let targetDirPath = Path(targetDir)
    if (exists(targetDirPath)) {
        println("target dir ${targetDir} exists，skip downloading and unzipping")
        return 0
    } else {
        Directory.create(targetDirPath, recursive: true)
    }

    // download stdx zip file
    if (!exists(zipFile)) {
        println("download from ${url} ...")
        let downloadProc = if (os == "windows") {
            launch("powershell", ["-Command", "Invoke-WebRequest", "-Uri", url, "-OutFile", zipFile])
        } else {
            launch("curl", ["-L", "-o", zipFile, url])
        }
        let downloadResult = downloadProc.wait()

        if (downloadResult != 0) {
            println("download failed for ${url}")
            remove(targetDirPath)
            return downloadResult
        }
    }

    // unzip file
    println("unzip file ${zipFile} to ${targetDir}...")
    let unzipProc = if (os == "windows") {
        launch("powershell", ["-Command", "Expand-Archive", "-Path", zipFile, "-DestinationPath", targetDir, "-Force"])
    } else {
        launch("unzip", ["-q", zipFile, "-d", targetDir])
    }
    let unzipResult = unzipProc.wait()

    // delete zip file
    let filePath = Path(zipFile)
    remove(filePath)

    if (unzipResult != 0) {
        println("unzipping failed")
        remove(targetDirPath)
        return unzipResult
    }

    return 0
}

func stagePreBuild(): Int64 {
    // Try to get target from environment variable (set by cjpm)
    let cjpmTarget = getVariable("CJPM_TARGET")
    let envTarget = getVariable("TARGET")
    let target = if (cjpmTarget.isSome()) {
        cjpmTarget
    } else {
        envTarget
    }
    
    var targetOs = ""
    var targetArch = ""
    
    // Parse target triple like "aarch64-linux-ohos" or "x86_64-linux-ohos"
    if (target.isSome()) {
        let targetStr = target.getOrThrow()
        println("Detected target: ${targetStr}")
        
        if (targetStr.contains("aarch64-linux-ohos")) {
            targetOs = "linux"
            targetArch = "aarch64"
        } else if (targetStr.contains("x86_64-linux-ohos")) {
            targetOs = "linux"
            targetArch = "x64"  // OHOS x86_64 uses "x64" in URL
        } else {
            // Fallback to host architecture
            let (os, arch) = getOsInfo()
            targetOs = os
            targetArch = arch
        }
    } else {
        // Fallback to host architecture
        let (os, arch) = getOsInfo()
        targetOs = os
        targetArch = arch
    }
    
    // For OHOS targets, ensure correct arch
    // Also check DEVECO_CANGJIE_HOME to handle DevEco Studio scenarios
    // where user compiles HAP on Windows/macOS host but targets OHOS device
    var isOhosTarget = false
    let devEcoHome = getVariable("DEVECO_CANGJIE_HOME")
    if ((target.isSome() && target.getOrThrow().contains("ohos")) || devEcoHome.isSome()) {
        isOhosTarget = true
        if (target.isSome() && target.getOrThrow().contains("aarch64")) {
            targetArch = "aarch64"
        } else if (target.isSome() && target.getOrThrow().contains("x86_64")) {
            targetArch = "x64"  // OHOS x86_64 uses "x64" in URL
        } else if (!target.isSome() && devEcoHome.isSome()) {
            // If DEVECO_CANGJIE_HOME is set but no explicit target, assume aarch64 (most common for phones)
            targetArch = "aarch64"
        }
    }

    if (targetOs == "unknown" || targetArch == "unknown") {
        println("unsupported os or arch")
        return 1
    }

    println("os: ${targetOs}, arch: ${targetArch}, isOhos: ${isOhosTarget}")
    return downloadAndExtract(targetOs, targetArch, isOhosTarget: isOhosTarget)
}

main(): Int64 {
    match (Process.current.arguments[0]) {
        case "pre-build" => stagePreBuild()
        case _ => 0
    }
}
