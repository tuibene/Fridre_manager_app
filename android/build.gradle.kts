plugins {
    id("com.android.application") apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

val newBuildDir = rootProject.layout.projectDirectory.dir("../../build")
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    evaluationDependsOn(":app")

    val newSubprojectBuildDir = rootProject.layout.buildDirectory.dir(project.name)
    layout.buildDirectory.set(newSubprojectBuildDir)

    plugins.withId("com.android.application") {
        extensions.configure<com.android.build.gradle.BaseExtension> {
            ndkVersion = "27.0.12077973"
        }
    }
}
