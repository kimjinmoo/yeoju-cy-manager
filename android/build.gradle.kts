allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    // Windows에서 Pub Cache(C:\)와 프로젝트(D:\) 드라이브가 다를 때
    // 플러그인의 buildDirectory를 다른 드라이브로 옮기면 Jacoco 등 태스크에서
    // "this and base files have different roots" 오류가 발생하므로 동일 루트일 때만 재배치한다.
    val projectRoot = project.projectDir.toPath().root
    val buildRoot = newBuildDir.asFile.toPath().root
    if (projectRoot == buildRoot) {
        val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
        project.layout.buildDirectory.value(newSubprojectBuildDir)
    }

    // Pub Cache의 외부 Android 라이브러리 플러그인(예: flutter_secure_storage) 내부 Lint 오류로
    // 프로젝트 전체 빌드가 중단되지 않도록 라이브러리 모듈의 Lint 오류 중단을 비활성화한다.
    plugins.withId("com.android.library") {
        extensions.configure(com.android.build.api.dsl.LibraryExtension::class.java) {
            lint {
                abortOnError = false
                checkReleaseBuilds = false
            }
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
