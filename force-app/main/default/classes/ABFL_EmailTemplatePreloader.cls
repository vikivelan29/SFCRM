public class ABFL_EmailTemplatePreloader {
    @AuraEnabled
    public static String getSendEmailUrl(Id recordId, String emailTemplateId) {
        // Generate URL for Send Email action with preloaded template
        PageReference emailPage = new PageReference('/email/author/emailauthor.jsp');
        emailPage.getParameters().put('p3_lkid', recordId); // Target record ID
        emailPage.getParameters().put('template_id', emailTemplateId); // Email template ID
        emailPage.getParameters().put('retURL', '/' + recordId); // Return URL after sending
        emailPage.getParameters().put('new_template', 'true'); // Use the email template

        return emailPage.getUrl();
    }
        public static String convertTextToHtml(String inputText) {
        if (String.isBlank(inputText)) {
            return '';
        }
        
        // Replace paragraph breaks (\n\n or \r\n\r\n) with <p></p>
        String htmlText = inputText.replaceAll('(\r\n|\n){2,}', '<p></p>');
        
        // Replace single line breaks (\n or \r\n) with <br>
        htmlText = htmlText.replaceAll('(\r\n|\n)', '<br>');

        // Replace tab spaces (\t) with HTML entity for tab space (&emsp;)
        htmlText = htmlText.replaceAll('\t', '&emsp;');

        return htmlText;
    }
    public static String getHtmlBodySuffix(){
        return '</td></tr></table></td></tr></table></td></tr></table></td></tr></table></body></html>';
    }
    public static String getHtmlBodyPrefix(){
        return '<html><head><title></title><meta content="text/html; charset=utf-8" /><meta name="viewport" content="width=device-width, initial-scale=1.0" /><meta name="format-detection" content="telephone=no" /><meta name="x-apple-disable-message-reformatting" /><title></title><style type="text/css">#outlook a {padding: 0;}.ReadMsgBody,.ExternalClass {width: 100%;}.ExternalClass,.ExternalClass p,.ExternalClass td,.ExternalClass div,.ExternalClass span,.ExternalClass font {line-height: 100%;}div[style*="margin: 14px 0"],div[style*="margin: 16px 0"] {margin: 0 !important;}table,td {mso-table-lspace: 0;mso-table-rspace: 0;}table,tr,td {border-collapse: collapse;}body,td,th,p,div,li,a,span {-webkit-text-size-adjust: 100%;-ms-text-size-adjust: 100%;mso-line-height-rule: exactly;}img {border: 0;outline: none;line-height: 100%;text-decoration: none;-ms-interpolation-mode: bicubic;}a[x-apple-data-detectors] {color: inherit !important;text-decoration: none !important;}body {margin: 0;padding: 0;width: 100% !important;-webkit-font-smoothing: antialiased;}.pc-gmail-fix {display: none;display: none !important;}@media screen and (min-width: 621px) {.pc-email-container {width: 620px !important;}}@media screen and (max-width:620px) {.pc-sm-p-20 {padding: 20px !important;}.pc-sm-p-30-20-25 {padding: 30px 20px 25px !important;}.pc-sm-fs-30 {font-size: 30px !important;}.pc-sm-fs-18 {font-size: 18px !important;}.pc-sm-p-35-10-15 {padding: 35px 10px 15px !important;}.pc-sm-mw-50pc {max-width: 50% !important;border-left: none!important;}}@media screen and (max-width:525px) {.pc-xs-p-10 {padding: 10px !important;}.pc-xs-p-25-10-20 {padding: 25px 10px 20px !important;}.pc-xs-fs-16 {font-size: 16px !important;}.pc-xs-br-disabled br {display: none !important;}.pc-xs-p-25-0-5 {padding: 25px 0 5px !important;}.pc-xs-mw-100pc {max-width: 100% !important;}}</style></head><body style="margin: 0px; padding: 0px; -webkit-font-smoothing: antialiased; text-size-adjust: 100%; background-color: rgb(255, 255, 255); width: 100% !important; height: auto; min-height: auto;"><table border="0" cellpadding="0" cellspacing="0" class="pc-email-body" style="table-layout: fixed;" width="100%"><tr><td align="center" class="pc-email-body-inner" valign="top"><table align="center" border="0" cellpadding="0" cellspacing="0" class="pc-email-container" style="margin: 0 auto; max-width: 620px;background: #fff;border: 1px solid;" width="100%"><tr><td align="left" style="padding:0px;" valign="top"><table border="0" cellpadding="0" cellspacing="0" width="100%"><tr><td bgcolor="#ffffff" style="padding: 0px 20px; background: #ffffff; border-radius: 8px" valign="top"><table border="0" cellpadding="0" cellspacing="0" width="100%"><tr><td class="pc-sm-fs-18 pc-xs-fs-16 pc-fb-font" style="font-family:Anek Latin;font-size: 16px; line-height: 25px; letter-spacing: -0.2px; color: #4d4d4f;padding-left: 0px; padding-right: 0px" valign="top">&nbsp;</td></tr><tr><td class="pc-sm-fs-18 pc-xs-fs-16 pc-fb-font" style="font-family:\'Anek Latin\'; font-size: 16px; line-height: 25px; color: #4d4d4f; padding-top: 0px; padding-left: 0px; padding-right: 0px;" valign="top"><div style="margin-right: 4px; margin-left: 4px; text-align:justify">';
    }
    @AuraEnabled
    public static Id createEmailDraft(Id caseId, String subject, String body, String toAddress, String emailTemplateId) {
        Case caseRecord = [SELECT Id, Contact.Email,eBOT_Email_Draft__c FROM Case WHERE Id = :caseId LIMIT 1];

        // Create a draft email
        EmailMessage draft = new EmailMessage();
        draft.RelatedToId = caseId; // Associate with the Case
        
        draft.HtmlBody = getHtmlBodyPrefix() + convertTextToHtml(caseRecord.eBOT_Email_Draft__c) + getHtmlBodySuffix(); 
        draft.ToAddress = toAddress != null ? toAddress : caseRecord.Contact.Email;
        draft.EmailTemplateId = emailTemplateId;
        insert draft;

        return draft.Id;
    }
}