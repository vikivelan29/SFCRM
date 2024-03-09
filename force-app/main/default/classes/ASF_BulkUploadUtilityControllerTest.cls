@IsTest
public without sharing class ASF_BulkUploadUtilityControllerTest {
    
    @IsTest
    static void negativeScenarios(){
        ASF_Bulk_Upload_Header__c headObj = new ASF_Bulk_Upload_Header__c();
        headObj.Template_Name__c = 'Create_Case';
        headObj.Total_Rows__c = 1;
        headObj.Status__c = 'Pending';
        insert headObj;

        List<ASF_Bulk_Upload_Line_Item__c> lineItems = new List<ASF_Bulk_Upload_Line_Item__c>();
        for(Integer index = 0; index<1001; index++){
            ASF_Bulk_Upload_Line_Item__c lineItem = new ASF_Bulk_Upload_Line_Item__c();
            lineItem.JSON_Data__c = '[{}]';
            lineItem.Status__c = 'Pending';
            lineItem.Bulk_Upload_Header__c = headObj.Id;
            lineItems.add(lineItem);
        }

        Test.startTest();
        ASF_BulkUploadUtilityController.ChunkLoadWrapper wrapOne = ASF_BulkUploadUtilityController.insertLineItemsChunk(new List<ASF_Bulk_Upload_Line_Item__c>());
        ASF_BulkUploadUtilityController.ChunkLoadWrapper wrapTwo = ASF_BulkUploadUtilityController.insertLineItemsChunk(lineItems);
        Test.stopTest();
        
        //Assert.isFalse(wrapOne.isSuccess, 'IsSuccess expected to be false');
        
    }

    @IsTest
    static void insertHeaderRowWithLineItems_Test(){
        List<ASF_Bulk_Upload_Line_Item__c> lineItems = new List<ASF_Bulk_Upload_Line_Item__c>();
        ASF_Bulk_Upload_Line_Item__c lineItem = new ASF_Bulk_Upload_Line_Item__c();
        lineItem.JSON_Data__c = '{}';
        lineItem.Status__c = 'Pending';
        lineItems.add(lineItem);
        Test.startTest();
        ASF_BulkUploadUtilityController.insertHeaderRowWithLineItems(lineItems, 1, 'Create_Case');
        Test.stopTest();
        List<ASF_Bulk_Upload_Header__c> heads = [Select Id from ASF_Bulk_Upload_Header__c];
        Assert.areEqual(1, heads.size(), 'One Bulk Header was expected');
    }

    @IsTest
    static void insertLineItemsChunk_Test(){
        ASF_Bulk_Upload_Header__c headObj = new ASF_Bulk_Upload_Header__c();
        headObj.Template_Name__c = 'Create_Case';
        headObj.Total_Rows__c = 1;
        headObj.Status__c = 'Pending';
        insert headObj;

        List<ASF_Bulk_Upload_Line_Item__c> lineItems = new List<ASF_Bulk_Upload_Line_Item__c>();
        ASF_Bulk_Upload_Line_Item__c lineItem = new ASF_Bulk_Upload_Line_Item__c();
        lineItem.JSON_Data__c = '{}';
        lineItem.Status__c = 'Pending';
        lineItem.Bulk_Upload_Header__c = headObj.Id;
        lineItems.add(lineItem);

        Test.startTest();
        ASF_BulkUploadUtilityController.ChunkLoadWrapper wrap = ASF_BulkUploadUtilityController.insertLineItemsChunk(lineItems);
        Test.stopTest();
        
        Assert.isTrue(wrap.isSuccess, 'IsSuccess expected to be true');
    }

    /*@IsTest
    static void insertLastLineItemsChunk_Test(){
        ASF_Bulk_Upload_Header__c headObj = new ASF_Bulk_Upload_Header__c();
        headObj.Template_Name__c = 'Create_Case';
        headObj.Total_Rows__c = 1;
        headObj.Status__c = 'Pending';
        insert headObj;

        List<ASF_Bulk_Upload_Line_Item__c> lineItems = new List<ASF_Bulk_Upload_Line_Item__c>();
        ASF_Bulk_Upload_Line_Item__c lineItem = new ASF_Bulk_Upload_Line_Item__c();
        lineItem.JSON_Data__c = '{}';
        lineItem.Status__c = 'Pending';
        lineItem.Bulk_Upload_Header__c = headObj.Id;
        lineItems.add(lineItem);

        Test.startTest();
        ASF_BulkUploadUtilityController.ChunkLoadWrapper wrap = ASF_BulkUploadUtilityController.insertLastLineItemsChunk(lineItems, headObj.Id);
        Test.stopTest();
        
        Assert.isTrue(wrap.isSuccess, 'IsSuccess expected to be true');
    } */

    @IsTest
    static void markUploadCompleted_Test(){
        ASF_Bulk_Upload_Header__c headObj = new ASF_Bulk_Upload_Header__c();
        headObj.Template_Name__c = 'Create_Case';
        headObj.Total_Rows__c = 1;
        headObj.Status__c = 'Pending';
        insert headObj;

        Test.startTest();
        ASF_BulkUploadUtilityController.ChunkLoadWrapper wrap = ASF_BulkUploadUtilityController.markUploadCompleted(headObj.Id);
        Test.stopTest();
        Assert.isTrue(wrap.isSuccess, 'IsSuccess expected to be true');
    }

    @IsTest
    static void startProcessingChunks_Test_Queueable(){
        ASF_Bulk_Upload_Header__c headObj = new ASF_Bulk_Upload_Header__c();
        headObj.Template_Name__c = 'Create_Case';
        headObj.Total_Rows__c = 10001;
        headObj.Status__c = 'Pending';
        insert headObj;

        Test.startTest();
        ASF_BulkUploadUtilityController.ChunkLoadWrapper wrap = ASF_BulkUploadUtilityController.startProcessingChunks(headObj.Id, 10001, 'Create_Case');
        Test.stopTest();
        Assert.isTrue(wrap.isSuccess, 'IsSuccess expected to be true');
    }

    @IsTest
    static void startProcessingChunks_Test_Sync(){
        ASF_Bulk_Upload_Header__c headObj = new ASF_Bulk_Upload_Header__c();
        headObj.Template_Name__c = 'Create_Case';
        headObj.Total_Rows__c = 1001;
        headObj.Status__c = 'Pending';
        insert headObj;

        List<ASF_Bulk_Upload_Line_Item__c> lineItems = new List<ASF_Bulk_Upload_Line_Item__c>();
        for(Integer index = 0; index<1001; index++){
            ASF_Bulk_Upload_Line_Item__c lineItem = new ASF_Bulk_Upload_Line_Item__c();
            lineItem.JSON_Data__c = '{}';
            lineItem.Status__c = 'Pending';
            lineItem.Bulk_Upload_Header__c = headObj.Id;
            lineItems.add(lineItem);
        }
        insert lineItems;

        Test.startTest();
        ASF_BulkUploadUtilityController.ChunkLoadWrapper wrap = ASF_BulkUploadUtilityController.startProcessingChunks(headObj.Id, 1001, 'Create_Case');
        Test.stopTest();
        Assert.isTrue(wrap.isSuccess, 'IsSuccess expected to be true');
        
    }

    @IsTest
    static void ASF_BulkCaseProcessorUtility_process_test(){
        ASF_Bulk_Upload_Header__c headObj = new ASF_Bulk_Upload_Header__c();
        headObj.Template_Name__c = 'Create_Case';
        headObj.Total_Rows__c = 100;
        headObj.Status__c = 'Pending';
        insert headObj;

        List<ASF_Bulk_Upload_Line_Item__c> lineItems = new List<ASF_Bulk_Upload_Line_Item__c>();
        for(Integer index = 0; index<100; index++){
            ASF_Bulk_Upload_Line_Item__c lineItem = new ASF_Bulk_Upload_Line_Item__c();
            lineItem.JSON_Data__c = '{"Subject":"SampleSubject", "Status":"New"}';
            lineItem.Status__c = 'Pending';
            lineItem.Bulk_Upload_Header__c = headObj.Id;
            lineItems.add(lineItem);
        }
        insert lineItems;

        Test.startTest();
        ASF_BulkUploadUtilityController.ChunkLoadWrapper wrap = ASF_BulkUploadUtilityController.startProcessingChunks(headObj.Id, 100, 'Create_Case');
        Test.stopTest();
        Assert.isTrue(wrap.isSuccess, 'IsSuccess expected to be true');
        
    }

    @IsTest
    static void ASF_BulkCaseProcessorQueueable_test(){
        ASF_Bulk_Upload_Header__c headObj = new ASF_Bulk_Upload_Header__c();
        headObj.Template_Name__c = 'Create_Case';
        headObj.Total_Rows__c = 10001;
        headObj.Status__c = 'Pending';
        insert headObj;

        List<ASF_Bulk_Upload_Line_Item__c> lineItems = new List<ASF_Bulk_Upload_Line_Item__c>();
        for(Integer index = 0; index<=1001; index++){
            ASF_Bulk_Upload_Line_Item__c lineItem = new ASF_Bulk_Upload_Line_Item__c();
            lineItem.JSON_Data__c = '{"Subject":"SampleSubject", "Status":"New"}';
            lineItem.Status__c = 'Pending';
            lineItem.Bulk_Upload_Header__c = headObj.Id;
            lineItems.add(lineItem);
        }
        insert lineItems;

        Test.startTest();
        ASF_BulkUploadUtilityController.ChunkLoadWrapper wrap = ASF_BulkUploadUtilityController.startProcessingChunks(headObj.Id, 10001, 'Create_Case');
        Test.stopTest();
        Assert.isTrue(wrap.isSuccess, 'IsSuccess expected to be true');
        
    }

    @IsTest
    static void ASF_BulkRetryStuckLineItemsBatch_Test(){
        ASF_Bulk_Upload_Header__c headObj = new ASF_Bulk_Upload_Header__c();
        headObj.Template_Name__c = 'Create_Case';
        headObj.Total_Rows__c = 1001;
        headObj.Status__c = 'Pending';
        insert headObj;

        List<ASF_Bulk_Upload_Line_Item__c> lineItems = new List<ASF_Bulk_Upload_Line_Item__c>();
        for(Integer index = 0; index<=200; index++){
            ASF_Bulk_Upload_Line_Item__c lineItem = new ASF_Bulk_Upload_Line_Item__c();
            lineItem.JSON_Data__c = '{"Subject":"SampleSubject", "Status":"New"}';
            lineItem.Status__c = 'Event Fired';
            lineItem.Event_Fired_Date__c = System.now().addHours(-2);
            lineItem.Bulk_Upload_Header__c = headObj.Id;
            lineItems.add(lineItem);
        }
        insert lineItems;

        Test.startTest();
        Database.executeBatch(new ASF_BulkRetryStuckLineItemsBatch(), 2000);
        Test.stopTest();
        ASF_Bulk_Upload_Header__c head = [Select Id, Status__c from ASF_Bulk_Upload_Header__c where Id = :headObj.Id];
        Assert.areEqual('Processed', head.Status__c, 'Status should be Processed');
        
    }
}