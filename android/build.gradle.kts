allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Set custom buildDir for root project
buildDir = file("../../build")

subprojects {
    // Set custom buildDir for each subproject
    buildDir = rootProject.file("../../build/${project.name}")
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.2'
    }
}
