

[For English description click here](https://github.com/PashaGH8101/sing-box-batch?tab=readme-ov-file#sing-box-batch-file-1)


#  Sing-box Batch File
![image](https://github.com/user-attachments/assets/bddb5cc0-a6e4-4783-b822-d91d6abe09eb)

این فایل bat برای راحتی استفاده از Sing-box در ویندوز طراحی شده است.

1. هر دو فایل مورد نیاز (`Sing-box.bat` و `Updater.ps1`) را دانلود و در یک پوشه قرار دهید.
2. بر روی `Sing-box.bat` کلیک کنید تا اجرا شود.
> [!CAUTION]
> <div dir="rtl"> این ابزار نیاز به دسترسی ادمین دارد ، زیرا حین اجرای هسته sing-box اگر در کانفیگ خود ، در قسمت Inbound یک TUN تعریف شده باشد ویندوز بدون دسترسی ادمین، اجازه ایجاد آن را نخواهد داد و VPN اجرا نخواهد شد </div>

![image](https://github.com/user-attachments/assets/fb0fd49f-2dba-4f12-9df9-505c94ea5751)


> [!TIP]
> <div dir="rtl"> TUN یک ابزار شبکه مجازی است که می‌تواند به عنوان یک ورودی (inbound) برای ایجاد یک تونل (یا واسط) در سیستم شما استفاده شود. این واسط به شما امکان می‌دهد تمام ترافیک برنامه‌ها و وب‌های خود را از طریق این تونل عبور دهید. با استفاده از این روش، تمام ترافیک ابتدا به واسط TUN ارسال می‌شود، جایی که می‌توان آن را پردازش، فیلتر یا تغییر داد و سپس به مقصد نهایی خود ارسال کرد.</div>





**مراحل اجرای برنامه:**

<div dir="rtl">1. ممکن است اولین بار که برنامه را اجرا می‌کنید هشداری دریافت کنید. آن را رد کنید (این هشدار مربوط به اجرای اسکریپت دانلود شده از اینترنت است و جای نگرانی نیست).</div>

<div dir="rtl">2. برای اجرای درست برنامه، گزینه‌های موجود را به ترتیب اجرا کنید:</div>

<div dir="rtl">

   
   - **گزینه اول: Install Or Update Sing-box core**
     - این گزینه به شما اجازه می‌دهد با یک کلیک، آخرین نسخه هسته Sing-box را دانلود و اجرا کنید. اگر هسته قبلاً دانلود شده باشد، نسخه فعلی با آخرین نسخه موجود چک و در صورت نیاز به‌روزرسانی می‌شود.
          

<div dir="rtl">
   
   - **گزینه دوم: Update the config file by a subscription link (Fetch the latest subscription from a URL)**
     - این گزینه به شما امکان می‌دهد آخرین نسخه لینک اشتراک خود (فرمت JSON) را از یک لینک HTTPS دانلود کنید. (حتما لینکی که به برنامه میدهید با http یا https شروع شود در غیر این صورت خطا خواهد داد)
       
     - بررسی درستی لینک و فرمت JSON انجام می‌شود. محتوای لینک باید مانند تصویر زیر باشد:
![image](https://github.com/user-attachments/assets/3292bc4a-4c47-4f7b-acd1-40baca70d9f0)


     - فایل دانلود شده به نام `temp.json` ذخیره و توسط دستور `sing-box check` بررسی می‌شود. اگر ایرادی داشته باشد، نمایش داده شده و ادامه نمی‌یابد.
     - پس از بررسی، فایل نهایی به نام `config.json` ذخیره می‌شود.
</div>

 
<div dir="rtl">

   - **گزینه سوم: Start the Sing-box Core**
     - با این گزینه، هسته Sing-box شروع به کار می‌کند. ممکن است اولین بار شروع هسته کمی زمان‌بر باشد.
</div>

   - **گزینه چهارم: Link to My Github For latest Information and Updates**
     - این گزینه لینک این مخزن را در مرورگر کامپیوترتان باز می‌کند.





**English:**


# Sing-box Batch File


This batch file simplifies Sing-box on Windows.

1. Download the required files (`Sing-box.bat` and `Updater.ps1`) into a folder.
2. Click on `Sing-box.bat` to run it.

**Note**: The batch file requires admin privileges. This is necessary if your configuration file uses a TUN connection in the inbound section. Running without admin rights will result in an error.

**Steps to Use the Tool:**
1. The first time you run the program, you might see a warning about running a script from the internet. You can safely ignore this warning.
2. Follow the steps below to use the tool correctly:

   - **Option 1: Install or Update Sing-box core**
     - This option allows you to download and run the latest Sing-box core with one click. If the core is already downloaded, it checks the current version against the latest available version and updates if necessary.

   - **Option 2: Update the config file by a subscription link**
     - This option lets you download and use the latest version of your subscription link (in JSON format) from a URL (must start with `https://`).
     - The tool verifies the link and JSON format. The content should look like the image below:
       ![image](https://github.com/user-attachments/assets/3292bc4a-4c47-4f7b-acd1-40baca70d9f0)
     - The downloaded file is saved as `temp.json` and checked using the `sing-box check` command. If there are errors, they are displayed and the process stops.
     - After validation, the final configuration is saved as `config.json`.

   - **Option 3: Start the Sing-box Core**
     - This option starts the Sing-box core. The first start might take some time as it downloads and applies all rulesets.

   - **Option 4: Link to My Github for Latest Information and Updates**
     - This option opens the repository link in your computer's browser.

