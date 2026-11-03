// 本机 Gradle 镜像（仅影响这台机器，不改项目配置）。
//
// 原因：JVM 到 dl.google.com / repo1.maven.org 的 TLS 握手被网络设备终止
// （curl 能通、Java 不通），表现为 "server may not support the client's requested
// TLS protocol versions"。aliyun 镜像可正常访问，且包含同样的构件。
//
// 作用：把所有 google() / mavenCentral() / gradlePluginPortal() 换成 aliyun 镜像。

// included build（如 flutter_tools/gradle 的 composite build）有自己的仓库策略，
// 往它们的 project.repositories 里加仓库会触发
// "prefer settings repositories over project repositories" 报错 —— 直接跳过。
if (gradle.parent != null) {
    return
}

def MIRRORS = [
    'https://maven.aliyun.com/repository/google',
    'https://maven.aliyun.com/repository/central',
    'https://maven.aliyun.com/repository/gradle-plugin',
]

def isBlocked = { repo ->
    if (!(repo instanceof org.gradle.api.artifacts.repositories.MavenArtifactRepository)) return false
    def u = repo.url.toString()
    return u.contains('dl.google.com') ||
           u.contains('maven.google.com') ||
           u.contains('repo1.maven.org') ||
           u.contains('repo.maven.apache.org') ||
           u.contains('plugins.gradle.org')
}

def rewrite = { handler ->
    // 已经存在的先摘掉
    def existing = []
    handler.each { r -> if (isBlocked(r)) existing << r }
    existing.each { r -> handler.remove(r) }
    // 之后再声明 google()/mavenCentral() 也直接摘掉，避免它们排在镜像前面
    handler.whenObjectAdded { r ->
        if (isBlocked(r)) {
            try { handler.remove(r) } catch (ignored) { }
        }
    }
    MIRRORS.each { m -> handler.maven { url = m } }
}

settingsEvaluated { settings ->
    rewrite(settings.pluginManagement.repositories)
}

allprojects { project ->
    rewrite(project.repositories)
    rewrite(project.buildscript.repositories)
}
