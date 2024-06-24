@isTest
private class FeedcommentHandlerTest {
@isTest
   static void testRestrictDeletionOfComment() {
        // Create FeedComment records
        Case cs1=new Case();
          cs1.Type_Text__c='Repayment Related';
          cs1.Sub_Type_Text__c='EMI Date Change';
          cs1.Nature__c='Request';
          Insert cs1;
       feeditem item1=new feeditem();
       item1.ParentId=cs1.Id;
       item1.Body='<p>Hello Testttttt</p>';
       insert item1;
       feedcomment feedcmt1=new feedcomment();
       // feedcmt1.parentId=cs1.Id;
        feedcmt1.CommentBody='Testing Done.';
        feedcmt1.FeedItemId=item1.Id;
        insert feedcmt1;
       Try{
        delete feedcmt1;
       }
       catch(DmlException e){
        system.debug('Error came-->'+e);
           //   System.assertEquals('Deletion is not allowed', e.getMessage());
       }
       /* List<FeedComment> feedComments = [select Id from feedcomment where parentid='cs1.Id'];
        Test.startTest();
        try {
            delete feedComments;
        } catch(DmlException e) {
            // Verify that deletion was not allowed and errors were added
                System.assertEquals('Deletion is not allowed', e.getMessage());
            }
        Test.stopTest();*/
       
    }

}