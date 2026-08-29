import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

fun releaseSigningProperty(name: String): String? =
    keystoreProperties.getProperty(name)?.trim()?.takeIf { it.isNotEmpty() }

val releaseSigningKeys = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
val releaseStoreFilePath = releaseSigningProperty("storeFile")
val hasReleaseKeystoreFile = releaseStoreFilePath?.let { file(it).isFile } == true
val hasReleaseSigningConfig = releaseSigningKeys.all { releaseSigningProperty(it) != null } && hasReleaseKeystoreFile

gradle.taskGraph.whenReady {
    val runsReleaseBuild = allTasks.any { task ->
        val taskName = task.name.lowercase()
        (taskName.startsWith("assemble") || taskName.startsWith("bundle") || taskName.startsWith("package")) &&
            taskName.contains("release")
    }

    if (runsReleaseBuild && !hasReleaseSigningConfig) {
        throw GradleException(
            "La firma release requiere android/key.properties con credenciales completas y un storeFile existente."
        )
    }
}

android {
    namespace = "com.artguz.english_reader_app"
    // Por encima del valor por defecto de Flutter (36) porque
    // flutter_secure_storage 11 compila contra la API 37 y Gradle exige que la
    // app compile al menos con la misma. No cambia el comportamiento en
    // ejecucion: eso lo define targetSdk, que sigue en el valor de Flutter.
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.artguz.english_reader_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (hasReleaseSigningConfig) {
                // La llave release nunca debe versionarse; Gradle solo lee la ruta local declarada.
                storeFile = file(releaseStoreFilePath!!)
                storePassword = releaseSigningProperty("storePassword")
                keyAlias = releaseSigningProperty("keyAlias")
                keyPassword = releaseSigningProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
