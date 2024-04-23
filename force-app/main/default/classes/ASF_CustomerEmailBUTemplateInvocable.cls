/**
 * Interface for BU's to implement custom Logic for Customer Emails 
 * and Returning Back the template names, as needed
 */
public interface ASF_CustomerEmailBUTemplateInvocable {
    
    /**
     * The Input is being passed from the Flow
     * The BU Class needs to check the Status, and if an exceptional 
     * or Supression scenario is present, then accordingly return back
     * the suppression flag, or the template name
     */
    Map<Id, ASF_CustomerEmailInvocable.EmailOutputWrapper> getCustomEmailData(List<ASF_CustomerEmailInvocable.EmailInputWrapper> caseData);
}