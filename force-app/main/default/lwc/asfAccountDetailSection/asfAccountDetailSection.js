/* Component Name : ksc_AccountDetailSection
** Description:This is the  component for Displaying Indicators card
** Author : Neeti Panda
** Created Date : Nov 23, 2022
** Last Modified Data : Nov 23, 2033
** Parent Story Number : NA
*/
import { LightningElement,track,api } from 'lwc';
//import getFieldWrapperDetails from '@salesforce/apex/ksc_AccountDetailsParserClass.generateFieldConfigWrapper';
//import initiateCallout from '@salesforce/apex/ASF_IntegrationCalloutHandler.initiateCallout';
import SystemModstamp from '@salesforce/schema/Account.SystemModstamp';
import errorMsg from '@salesforce/label/c.ASF_ErrorMessage';

export default class AsfAccountDetailSection extends LightningElement {
    @api prodName;
    @api accNumber;
    @api assetType;
    jsonParse = '';
    @api lstDisplay =[];
    @api nomineeDisplay=[];
    @api showError = false;
    @api lstTabName;
    @track errorMessage;
    @track showSpinner = false;
    @track displayResult;
    @track nomineeData;
    @track nomineeColumns;
    @track partyData;
    @track partyColumns;
    //@api assetDetailJson;
    @track objAsset;
    assetid ;
    objTabVisibilty={};
    label = {
        errorMsg,
    };

    @api get assetDetailJson() {
        return this.objAsset;
    }
    set assetDetailJson(value) {
        this.setAttribute('objAsset', value);
        this.objAsset = value;
       
        let parsedJsObj = JSON.parse(this.objAsset);
        this.assetid = parsedJsObj.Id ;
        this.accNumber = parsedJsObj.Name;
        this.cardDisplay = parsedJsObj.Product_Code__c ? parsedJsObj.Name+' : '+parsedJsObj.Product_Code__c : parsedJsObj.Name;
        //this.makeAPICall();
        if(this.template.querySelector('lightning-tabset') != null){
            this.template.querySelector('lightning-tabset').activeTabValue = 'Account Info';
        }
    }

    //inputjson = '[{\"nominee\":\"testname\",\"relationship\":\"Father\",\"contribution\":\"50\"},{\"nominee\":\"testname2\",\"relationship\":\"Mother\",\"contribution\":\"50\"}]';
    
    /****************************************************
     * @Description - Works on onload of LWC component.     
     * @param  -    none
    *****************************************************/
    
    connectedCallback() {
        try{
            //this.makeAPICall();
            this.checkTabVisibility();
        }
        catch(error){
            this.showError = true;
            this.errorMessage = error.message;
        }

    }
    handleRetry(){
        try{
            //this.makeAPICall();
        }
        catch(error){
            this.showError = true;
            this.errorMessage = error.message;
        }
    }

    makeAPICall(){
        this.showSpinner = true;
        
        initiateCallout({
            strRecordId: this.accNumber,
            strSettingName: 'AccountDetails_API',
        })
        .then(result => {
            var jsonParse='';
            var strBody='';
            if(result != null && result != ''){
                this.jsonParse = result;
                this.strBody =this.jsonParse.strResponseBody;
                if(this.jsonParse.strResponseStatusCode == '200'){
                    if(this.jsonParse.strResponseBody != null){
                        this.displayResult= JSON.parse(this.strBody);

                        if(this.displayResult.partyDetails != null){
                            this.partyColumns = this.displayResult.partyDetails.columns;
                            var resultData = JSON.parse(this.displayResult.partyDetails.rowData);
                            if(resultData != null && resultData.length >0){
                                this.partyData = resultData;
                            }
                        }
                        

                        if(this.displayResult.nomineeDetails != null){
                            this.nomineeColumns = this.displayResult.nomineeDetails.columns;
                            var resultData1 = JSON.parse(this.displayResult.nomineeDetails.rowData);
                            if(resultData1 != null && resultData1.length >0){
                                this.nomineeData = resultData1;
                            }
                        }
                        if(this.displayResult.freezeDetails != null){
                            this.freezeColumns = this.displayResult.freezeDetails.columns;
                            var resultData2 = JSON.parse(this.displayResult.freezeDetails.rowData);
                            if(resultData2 != null && resultData2.length >0){
                                this.freezeData = resultData2;
                            }
                        }
                    }
                    this.showError = false;
                    this.showSpinner = false;
                }else{
                    this.partyData = null;
                    this.nomineeData = null;
                    this.showError = true;
                    this.showSpinner = false;
                    this.errorMessage = this.jsonParse.strResponseBody;
                }
            }
            else{
                this.partyData = null;
                this.nomineeData = null;
                this.showError = true;
                this.showSpinner = false;
                this.errorMessage = this.label.errorMsg;
            }
        })
        .catch(error => { 
            this.partyData = null;
            this.nomineeData = null;
            this.showSpinner = false;
            this.showError = true;
            this.errorMessage = this.label.errorMsg;
            this.addErrorLog(error.message);
        });
    }
    addErrorLog(error_message) {
        console.log('Error ' + error_message);
    }

    /********************************************************************
     * @Description - Method to check Tab Visibility
    *********************************************************************/
     checkTabVisibility(){
        var keys = Object.keys(this.lstTabName);
        if(keys!=null && keys.length>0){
            for (let i = 0; i < keys.length; i++) {
                if(keys[i] == "Accounts Details"){
                    this.objTabVisibilty.boolAccDetails = this.lstTabName[keys[i]].isVisibleOnUi;
                }
                else if (keys[i] == "Nominee"){
                    this.objTabVisibilty.boolNominee = this.lstTabName[keys[i]].isVisibleOnUi;
                }
                else if (keys[i] == "Related Party"){
                    this.objTabVisibilty.boolRelParty = this.lstTabName[keys[i]].isVisibleOnUi;
                }
                else if (keys[i] == "Lien Details"){
                    this.objTabVisibilty.boolLienDetail= this.lstTabName[keys[i]].isVisibleOnUi;
                }
                else if (keys[i] == "Balance Inquiry"){
                    this.objTabVisibilty.boolBalInq = this.lstTabName[keys[i]].isVisibleOnUi;
                }
                else if (keys[i] == "Limit-Drawing Power"){
                    this.objTabVisibilty.boolLimitDrawingPower = this.lstTabName[keys[i]].isVisibleOnUi;
                }
                else if (keys[i] == "Limit-Sanction"){
                    this.objTabVisibilty.boolLimitSanction = this.lstTabName[keys[i]].isVisibleOnUi;
                }
                else if (keys[i] == "Transactions"){
                    this.objTabVisibilty.boolTransactions = this.lstTabName[keys[i]].isVisibleOnUi;
                }
                else if (keys[i] == "Freeze Details"){
                    this.objTabVisibilty.boolFreezeDetails = this.lstTabName[keys[i]].isVisibleOnUi;
                }
            }
        }
    }
}