buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Ini adalah plugin Google Services yang perlu ditambahkan
        classpath("com.google.gms:google-services:4.4.1") // <-- TAMBAHKAN BARIS INI
        // Periksa https://developers.google.com/android/guides/google-services-plugin untuk versi terbaru jika ada
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
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
