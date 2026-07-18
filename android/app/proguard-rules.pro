# flutter_local_notifications 用 Gson 反序列化 BigDecimal 数组等
# 通知模型，泛型参数在 R8/ProGuard 中若被擦除则 cancelAll()、getActiveNotifications() 等
# method channel 调用会抛 "Missing type parameter"，导致 release 包里
# 任何走 rescheduleFromDb() 的路径（冷启动 / 增删改 / 备份导入刷新）
# 误以为失败。本规则保留 dart 端映射到的所有 model 类及其泛型签名。

-keepattributes Signature,*Annotation*,InnerClasses,EnclosingMethod
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.dexterous.** { *; }
-keep class * implements com.google.gson.JsonSerializer { *; }
-keep class * implements com.google.gson.JsonDeserializer { *; }
-keep class * implements com.google.gson.TypeAdapter { *; }
-keep class * implements com.google.gson.TypeAdapterFactory { *; }
-keep class * extends com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-dontwarn com.google.errorprone.**
