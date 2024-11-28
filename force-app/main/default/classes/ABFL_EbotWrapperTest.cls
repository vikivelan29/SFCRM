@isTest
public class ABFL_EbotWrapperTest {

    @isTest
    static void testEbotResponseWrapper() {
        ABFL_EbotWrapper.EbotResponseWrapper ebotResponse = new ABFL_EbotWrapper.EbotResponseWrapper();
        ebotResponse.AUTOCLOSURE_IN_RR = 'Test Auto Closure';
        ebotResponse.CASEID = 'Test Case ID';
        ebotResponse.CASESUBTYPE = 'Test Case Subtype';
        ebotResponse.COMMENT = 'Test Comment';
        ebotResponse.CONFIDENCESCORE = 'Test Confidence Score';
        ebotResponse.CUSTOMERNO = 'Test Customer Number';
        ebotResponse.ISATTACHMENTFLAG = 'Test Attachment Flag';
        ebotResponse.ISMULTIPLELAN = 'Test Multiple LAN';
        ebotResponse.ISREGISTEREDCUSTOMER = 'Test Registered Customer';
        ebotResponse.ISSMT = 'Test Senior Management';
        ebotResponse.LAN = 'Test LAN';
        ebotResponse.LOB = 'Test LOB';
        ebotResponse.MOODSTAMP = 'Test Mood Stamp';
        ebotResponse.OWNERFULLNAME = 'Test Owner Full Name';
        ebotResponse.PAYTMINTERACTIONID = 'Test PAYTM Interaction ID';
        ebotResponse.PRIORITY = 'Test Priority';
        ebotResponse.AUTORESPONSEFLAG = 'Test Auto Response Flag';
        ebotResponse.DISPOSITION = 'Test Disposition';

        System.assertEquals('Test Auto Closure', ebotResponse.AUTOCLOSURE_IN_RR,'record is there');
        System.assertEquals('Test Case ID', ebotResponse.CASEID,'record is there');
        System.assertEquals('Test Case Subtype', ebotResponse.CASESUBTYPE,'record is there');
        System.assertEquals('Test Comment', ebotResponse.COMMENT,'record is there');
        System.assertEquals('Test Confidence Score', ebotResponse.CONFIDENCESCORE,'record is there');
        System.assertEquals('Test Customer Number', ebotResponse.CUSTOMERNO,'record is there');
        System.assertEquals('Test Attachment Flag', ebotResponse.ISATTACHMENTFLAG,'record is there');
        System.assertEquals('Test Multiple LAN', ebotResponse.ISMULTIPLELAN,'record is there');
        System.assertEquals('Test Registered Customer', ebotResponse.ISREGISTEREDCUSTOMER,'record is there');
        System.assertEquals('Test Senior Management', ebotResponse.ISSMT,'record is there');
        System.assertEquals('Test LAN', ebotResponse.LAN,'record is there');
        System.assertEquals('Test LOB', ebotResponse.LOB,'record is there');
        System.assertEquals('Test Mood Stamp', ebotResponse.MOODSTAMP,'record is there');
        System.assertEquals('Test Owner Full Name', ebotResponse.OWNERFULLNAME,'record is there');
        System.assertEquals('Test PAYTM Interaction ID', ebotResponse.PAYTMINTERACTIONID,'record is there');
        System.assertEquals('Test Priority', ebotResponse.PRIORITY,'record is there');
        System.assertEquals('Test Auto Response Flag', ebotResponse.AUTORESPONSEFLAG,'record is there');
        System.assertEquals('Test Disposition', ebotResponse.DISPOSITION,'record is there');
    }
}