allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

subprojects {
    plugins.withType<com.android.build.gradle.LibraryPlugin> {
        extensions.configure<com.android.build.gradle.LibraryExtension> {
            if (namespace == null) {
                namespace = project.name
            }
        }
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
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
