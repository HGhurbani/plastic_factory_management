# مسارات العمل للتطبيق

هذا المستند يشرح خطوات سير العمل في نظام إدارة مصنع البلاستيك مع تحديد الصفحات والصلاحيات الخاصة بكل دور مستخدم.

## مسار عملية الإنتاج

1. **إصدار أمر إنتاج**
   - **الدور المسؤول:** مسؤول إعداد طلبات الإنتاج.
   - **الصفحة:** `CreateProductionOrderScreen` (المسار `/production/create`).
   - يقوم المسؤول بتعبئة المنتج والكمية والباتش وربط الطلب بالقالب والماكينة ثم إرسال الأمر مع متابعة التالف والورديات ومراقبة الأداء.
2. **اعتماد الطلب**
   - **الدور المسؤول:** مدير المصنع أو مدير الإنتاج.
   - **الصفحة:** `ProductionOrdersListScreen` (المسار `/production/list`).
   - يظهر الطلب بالحالة "قيد الانتظار" ويمكن للمدير قبوله أو رفضه مع ذكر السبب.
3. **استلام مشرف تركيب القوالب**
   - **الدور المسؤول:** مشرف تركيب القوالب.
   - **الصفحة:** `ProductionOrderDetailScreen` مع زر "استلام المسؤولية" للمرحلة.
   - يتم توثيق الاستلام بالتاريخ والوقت وإمكانية إرفاق صور.
4. **تركيب القوالب**
   - **الدور المسؤول:** مشرف تركيب القوالب.
   - بعد الاستلام يقوم بإتمام مرحلة تركيب القوالب مع إمكانية إرفاق ملاحظات وصور.
5. **تسليم القالب لمشرف الإنتاج**
   - **الدور المسؤول:** مشرف الوردية / مشرف الإنتاج.
   - يتم قبول التسليم من شاشة تفاصيل الطلب وتسجيل توقيع الاستلام إن لزم.
6. **بدء الإنتاج**
   - **الدور المسؤول:** مشرف الوردية يحدد الآلة ويبدأ المرحلة.
   - **الدور المساعد:** مشغل الآلة يقوم بتشغيل الماكينة وتسجيل وقت البدء والانتهاء وقراءة العدادات من نفس الشاشة.
7. **إدارة المواد التالفة**
   - **الدور المسؤول:** مشرف الوردية يوثق الكميات التالفة وأسباب التلف ضمن تفاصيل الطلب.
8. **انتهاء الإنتاج وتسليم للمخزون**
   - **الدور المسؤول:** مشرف الوردية يعتمد انتهاء التشغيل ثم يسلم الكمية المنتجة للمخزون مع توقيع أمين المخزن.
9. **مراقبة الجودة والتخزين**
   - **الدور المسؤول:** مراقب الجودة يتفقد الطلب ويسجل نتيجة الفحص.
   - **الدور المساعد:** أمين المخزن يقوم بإضافة الكمية للمخزون من شاشة إدارة المخزون.

كل خطوة تحتفظ بالوقت والتاريخ والمستخدم المسؤول، مع إمكانية رفع الصور أو التوقيعات الرقمية عند الحاجة.

## مسار عملية المبيعات

1. **إنشاء طلب الشراء**
   - **الدور المسؤول:** مندوب المبيعات.
   - **الصفحة:** `CreateSalesOrderScreen` (المسار `/sales/orders/create`).
   - يختار العميل والمنتجات المطلوبة ثم يوقع العميل إلكترونياً.
2. **الاعتماد المالي**
   - **الدور المسؤول:** المحاسب.
   - **الصفحة:** `AccountingScreen` (المسار `/accounting`).
   - يراجع الطلبات الجديدة ويوافق عليها أو يرفضها.
3. **تحويل الطلب لمسؤول العمليات**
   - **الدور المسؤول:** مسؤول العمليات.
   - **الصفحة:** `SalesOrdersListScreen` (المسار `/sales/orders/list`).
   - يستلم الطلب المعتمد من المحاسب ويحدد أمين المخزن المكلف بالتجهيز.
4. **تجهيز الطلب وتحديد موعد التسليم**
   - **الدور المسؤول:** أمين المخزن.
   - **الصفحة:** `SalesOrdersListScreen` مع تحديد موعد التسليم وتوثيق أي تأخير.
5. **اعتماد الطلب من مسؤول العمليات**
   - **الدور المسؤول:** مسؤول العمليات.
   - **الصفحة:** `SalesOrdersListScreen` (المسار `/sales/orders/list`).
   - يراجع توثيق المخزن ويعتمد الطلب ليبدأ التنفيذ.

## الصلاحيات المختصرة لكل دور

| الدور | أهم الصفحات المسموح بها |
|-------|-------------------------|
| مدير المصنع/الإنتاج | جميع صفحات الإدارة بما فيها طلبات الإنتاج والمخزون والمبيعات والمالية |
| مسؤول العمليات | توجيه طلبات المبيعات للمخزون والتنسيق بين الأقسام |
| مسؤول إعداد طلبات الإنتاج | إصدار أوامر الإنتاج وربطها بالقوالب والماكينات، وتتبع التالف والورديات ومراقبة الأداء وتوثيق استلام القالب والتشغيل والتسليم |
| مشرف تركيب القوالب | استلام وتركيب القوالب في تفاصيل الطلب |
| مشرف الوردية | استلام القوالب وتشغيل الإنتاج وإدارة التلفيات وتسليم المخزون |
| مشغل الآلة | تسجيل تشغيل الآلة ووقت التوقف |
| مسؤول الصيانة | برنامج الصيانة للآلات |
| مندوب المبيعات | إدارة العملاء وإنشاء طلبات المبيعات الخاصة به |
| مراقب الجودة | صفحات الفحص والجودة |
| أمين المخزن | إدارة المخزون واستلام المنتجات النهائية |
| المحاسب | اعتماد طلبات المبيعات |


## وحدة المالية

تتيح هذه الوحدة للمحاسب مراجعة طلبات المبيعات وطلبات قطع الغيار قبل اعتمادها. كما توفر إدارة للمديونية من خلال تسجيل الدفعات وتحصيلها مما يؤدي إلى تحديث رصيد العميل تلقائياً. يمكن أيضاً تسجيل مصاريف المشتريات وربطها بسجلات الصيانة أو أوامر الإنتاج لاحتساب التكلفة بدقة.
