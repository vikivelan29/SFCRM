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
        List<EmailMessage> outgoingCaseEmails = new List<EmailMessage>();
        
        
        /* Check if the request is coming from User Action by Clicking on Quick Action - Email.
* Return if the request is not from Quick Action. All the automation to have Quiddity as SYNCHRONOUS
*/
        Request reqInfo = Request.getCurrent();
        String currentRequestId = reqInfo.getRequestId();
        Quiddity currentType = reqInfo.getQuiddity();
        if(currentType != Quiddity.QUICK_ACTION){
            if(!Test.isRunningTest()){
                return;
            }
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
 
    
}