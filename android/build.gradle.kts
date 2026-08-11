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
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    // The `printing` package (5.13.1) pins its own compileSdkVersion to 30, but
    // its bundled resources reference `android:attr/lStar` (introduced in API 31).
    // AGP 8.x surfaces this as a `verifyReleaseResources` AAPT error.
    // Forcing compileSdk to 36 on every subproject lets `printing`'s resources
    // resolve the attr without bumping the package itself. 36 is also the minimum
    // required by androidx.core:core-ktx:1.17.0 (pulled in transitively).
    afterEvaluate {
        if (project.hasProperty("android")) {
            val androidExt = (project.extensions.findByName("android") as? com.android.build.gradle.BaseExtension)
            androidExt?.compileSdkVersion(36)
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
