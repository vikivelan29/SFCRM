/****************************************************************************************************************
* @LOB - Framework
* @Description - Emailhelper for framework requirement.
* @Author - Virendra Patil
* 
*****************************************************************************************************************/
public class ASF_EmailMessageHelper {
    
    /* Validate if the email going out is from OrgWideDefaultOnly.
*/
    public static void validateIfGoingFromAuthorizedAddress(List<EmailMessage> newEmails){
        Map<String,Boolean> mEmailVsVerified = getOrgWideDefaultEmailsOnly();
        List<EmailMessage> outgoingCaseEmails = new List<EmailMessage>();
        
        
        /* Check if the request is coming from User Action by Clicking on Quick Action - Email.
         * Return if the request is not from Quick Action. All the automation to have Quiddity as SYNCHRONOUS
         */
        Request reqInfo = Request.getCurrent();
        String currentRequestId = reqInfo.getRequestId();
        Quiddity currentType = reqInfo.getQuiddity();
        if(currentType != Quiddity.QUICK_ACTION){
            return;
        }
        
        for (EmailMessage email : newEmails) {
            if(!email.Incoming && email.ParentId != null){
                if(email.ParentId.getSObjectType() == Case.sObjectType){
                    outgoingCaseEmails.add(email);
                }
            }
        }
        
        if(outgoingCaseEmails.size()>0){
            String loggedInUserEmail = UserInfo.getUserEmail();
            
            for(EmailMessage email : outgoingCaseEmails){
                if(loggedInUserEmail == email.ValidatedFromAddress){
                    email.addError('You are trying to send email from your email address. Please select authorized email address from the list.');
                }
            }
        }
    }
    /* Runs only in the case of Outbound Email. Returns the map of OrgWideDefault Email.
*/ 
    private static Map<String,Boolean> getOrgWideDefaultEmailsOnly() {
        Map<String,Boolean> mEmailVsVerified = new Map<String,Boolean>();
        
        List<OrgWideEmailAddress> orgWideEmails = [SELECT Id, IsVerified, Address, Purpose FROM OrgWideEmailAddress];
        if(orgWideEmails.size()>0){
            for(OrgWideEmailAddress owd : orgWideEmails){
                if(!mEmailVsVerified.containsKey(owd.Address))
                    mEmailVsVerified.put(owd.Address.toLowerCase().trim(),owd.IsVerified);
            }
        }
        return mEmailVsVerified;
    }
    /* Runs only in the case of Outbound Email.
*/ 
    public static void validateIfGoingOutFromNonUserAddress(List<EmailMessage> emails){
        
        Map<String,Boolean> mEmailVsVerified = getOrgWideDefaultEmailsOnly();
        Request reqInfo = Request.getCurrent();
        String currentRequestId = reqInfo.getRequestId();
        Quiddity currentType = reqInfo.getQuiddity();
        for(EmailMessage em : emails){
            if(currentType == Quiddity.QUICK_ACTION){
                if(mEmailVsVerified.containsKey(em.ValidatedFromAddress.toLowerCase().trim())){
                    if(!mEmailVsVerified.get(em.ValidatedFromAddress.toLowerCase().trim())){
                        em.addError('Please select authorized email to send outbound communications.');
                    }
                }
                else{
                    if(currentType == System.Quiddity.QUICK_ACTION){
                        em.addError('Please select authorized email to send outbound communications.');
                    }
                }
            }
        }
    }
    
}