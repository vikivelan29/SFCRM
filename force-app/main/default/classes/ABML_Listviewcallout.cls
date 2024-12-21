/******************************************************  
* Author           - Souvik Gosh
* Date             - 26-November-2024
* Description      - This class is used for getting the list view soql query's for ABML_QueueController
********************************************************
*/
Global without sharing class ABML_Listviewcallout {
      
    public static string doCallout(String listViewId){
         
        Http http = new Http();
        HTTPRequest httpReq = new HTTPRequest();
        String objName = 'Case';

        String endpoint = URL.getOrgDomainUrl().toExternalForm() + '/services/data/v37.0/sobjects/' + objName + '/listviews/' + listViewId + '/describe';
        httpReq.setEndpoint( endpoint );
        httpReq.setMethod( 'GET' );
        httpReq.setHeader( 'Content-Type', 'application/json; charset=UTF-8' );
        httpReq.setHeader( 'Accept', 'application/json' );
        string sessionId ;
        
        //String sessionId = 'Bearer ' + UserInfo.getSessionId();
        PageReference vfPage = Page.ABML_ListViewSession;
        sessionId = test.isrunningtest() ? userinfo.getsessionid() : 'Bearer ' + vfPage.getContent().toString();
       
        httpReq.setHeader( 'Authorization', sessionId );
        HTTPResponse httpRes = http.send( httpReq );
        system.debug('the res is'+httpRes.getBody());
        map<string,object> objmap = httpRes.getBody() != null ? (map<string,object>)json.deserializeUntyped(httpRes.getBody()) : new map<string,object>();
        string query = (string)objmap.get('query');
        return query;    
    }

}