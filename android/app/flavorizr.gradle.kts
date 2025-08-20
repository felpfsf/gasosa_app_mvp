import com.android.build.gradle.AppExtension

val android = project.extensions.getByType(AppExtension::class.java)

android.apply {
    flavorDimensions("env")

    productFlavors {
        create("dev") {
            dimension = "env"
            applicationId = "dev.etherealcodes.gasosaapp.dev"
            resValue(type = "string", name = "app_name", value = "Gasosa [Dev]")
        }
        create("prod") {
            dimension = "env"
            applicationId = "dev.etherealcodes.gasosaapp"
            resValue(type = "string", name = "app_name", value = "Gasosa")
        }
    }
}