/*******************************************************
*Class          :  RNWL_CommunicationFrameworkCntrlTest
*Author         :  Gaurav Sharma
*Created Date   :  21/10/2024
*Last Modified  :  21/10/2024
*@description   :  Test class for RNWL_CommunicationFrameworkController
********************************************************/
@isTest
public class RNWL_CommunicationFrameworkCntrlTest {
	@isTest
    public static void fetchCommunicationMDTTest(){
        List<RNWL_Communications__mdt> mdt= RNWL_CommunicationFrameworkController.fetchCommunicationMDT();
        system.debug(mdt);
   	}
}