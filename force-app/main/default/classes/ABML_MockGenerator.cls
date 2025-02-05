/******************************************************  
* Author           - Souvik Gosh
* Date             - 27-November-2024
* Description      - Mock callout class for ABML_Listviewcallout_Test
********************************************************
*/
@isTest
global class ABML_MockGenerator implements HttpCalloutMock {
    
        global HTTPResponse respond(HTTPRequest req) {
            // Create a mock HTTP response
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(200);
            //res.setMethod( 'GET' );
            res.setHeader('Content-Type', 'application/json');
           

            
            StaticResource resourceBody = [SELECT Id, Body FROM StaticResource WHERE Name = 'ABML_ListViewCalloutResource' LIMIT 1];
            String mockResponseBody = resourceBody.Body.toString();
            res.setBody(mockResponseBody);
            return res;
        }
    

   
}