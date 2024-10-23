import { LightningElement, wire, api, track } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getOppRec from '@salesforce/apex/RNWL_RenewalCustomerPolicyInfo.getOppRec';
import getNomineesClaims from '@salesforce/apex/RNWL_RenewalCustomerPolicyInfo.getNomineesClaims';
import getAPIResponse from '@salesforce/apex/RNWL_MemberDetailsController.getAPIResponseDetails';
import toastErrorMsg from '@salesforce/label/c.OppDetailsToastErrorMessage';

export default class RNWL_RenewalPolicyDetails extends LightningElement {
    label = { toastErrorMsg };

    @api recordId;policyId;accountId;
    @track account; policy; oppRec; heathRetrn; fitnessData;
    @track areDetailsVisible = false; renewalCheckFlag = false; nominees = []; 
    @track fitnessFlag = false; healthFlag = false;
    @track nomineeContacts; nomineesNames; claimsCounts; isPolicyRenewed;
    @track maturityDate; policyLapseDate; policyLapsed; policyStartDate; dateOfBirth; masterPolicyNumber;
    @track polRenewalNoticeDay;graceEndDate;graceStartDate; renStatus; inceptionDate;
    @track renewalAPIData; goGreenFlag; isChronic;
    @track autoDebitFlag; sumInsusedEnhancement; addressFlag; addressString;
    @track balanceHR;apiList;error;data;addDownloadStatus;

    @wire(getOppRec, {recordId: '$recordId'})
    record({ error, data}){
        if(data){ 
            this.oppRec = data;
            this.account = data.Account;
            this.policy = data.Policy__r;
            this.policyId = this.oppRec.Policy__c;
            try{
                if(this.account){
                    this.accountId = this.account.Id;
                    if( this.account.RecordType.Name == 'Non-Individual'){
                        this.apiList = ['Renewal Group Check', 'Health Return', 'AppRegDetails'];
                    }
                    else{
                        this.apiList = ['Renewal Check', 'Health Return', 'Fitness Assessment', 'AppRegDetails'];
                    }
                    this.addressString = this.account.BillingStreet ? (this.account.BillingStreet + ', ') : '';
                    this.addressString = this.addressString + (this.account.BillingCity ? (this.account.BillingCity + ', ') : '');
                    this.addressString = this.addressString + (this.account.BillingState ? this.account.BillingState : '');
                    this.addressString = this.addressString + (this.account.BillingPostalCode ? ('-'+this.account.BillingPostalCode) : '');
                    
                    this.addressFlag = this.account.BillingAddress ? true : false;
                    this.dateOfBirth = this.account.PersonBirthdate ? this.getISTDateFormat(new Date(this.account.PersonBirthdate)) : '';
                    this.isChronic = this.account.Is_Chronic__c;
                }
                if(this.policy){
                    this.policyStartDate = this.policy.Issue_Date__c ? this.getISTDateFormat(new Date(this.policy.Issue_Date__c)) : '';
                    this.maturityDate = this.policy.Maturity_Date__c ? this.getISTDateFormat(new Date(this.policy.Maturity_Date__c)) : '';

                    if(this.policy.Maturity_Date__c != null){
                        var matDate = new Date(this.policy.Maturity_Date__c);
                        this.policyLapseDate = this.getISTDateFormat(new Date(matDate.setDate(matDate.getDate() + 30)));
                    }   
                    this.goGreenFlag = this.policy.GoGreen__c;
                    this.masterPolicyNumber = this.policy.MasterPolicyNumber__r?.Name;
                }
                
                this.graceStartDate = this.oppRec.Grace_Period_Start__c ? this.getISTDateFormat(new Date(this.oppRec.Grace_Period_Start__c)) : '';
                this.graceEndDate = this.oppRec.Grace_Period_End__c ? this.getISTDateFormat(new Date(this.oppRec.Grace_Period_End__c)) : '';
                this.polRenewalNoticeDay = this.oppRec.Policy_Renewal_Notice_Day__c ? this.getISTDateFormat(new Date(this.oppRec.Policy_Renewal_Notice_Day__c)) : '';   
                this.inceptionDate = this.oppRec.Policy_Inception_Date__c ? this.getISTDateFormat(new Date(this.oppRec.Policy_Inception_Date__c)) : ''; 
                
                this.renStatus = this.oppRec.Status__c == 'Renewed' ? 'Payment Received' : 'In Progress';
                this.isPolicyRenewed = this.oppRec.Status__c == 'Renewed' ? 'Yes' : 'No';

                this.getNomiteeDetails();
                
                this.getAdditionalData();
                
                this.areDetailsVisible = true;
            } catch(e){
                console.log('Error displaying data : '+e.message);
            }
        } else {
            this.oppRec = undefined;
            this.error = error; 
            console.log('this.error----',this.error);
        }         
    }

    //////////////////////////////////Imperative methods//////////////////////////////////////////////////

    getAdditionalData(){

        getAPIResponse({ opportunityId : this.recordId, assetId: this.policyId, policyNum : this.oppRec.Proposal_Number__c, proposalNo : this.policy.SerialNumber, lstFileSrcAPI : this.apiList, accountId : this.accountId }).then(response => {            
            if(response){
                this.prepareAdditionalData(response);
            }
        }).catch(error =>{ 
            console.log('error----',error.message);
        });

    }

    prepareAdditionalData(data){
        
                let renCheckhArray = [];
                let healthArray = [];
                let fitnessArray = [];
                let apiErrMsg = '';

                for (let key in data) {

                    //For individual Or RUGs
                    if((key == 'Renewal Check' || key == 'Renewal Group Check') && data[key]){
                        if(JSON.parse(data[key]).error[0].ErrorCode != '00'){
                           apiErrMsg = 'Current Renewal Details';
                        }
                        else{
                            renCheckhArray = JSON.parse(data[key]).response.policyData;
                        }
                    }
                    //for Health returns
                    if(key == 'Health Return' && data[key]){
                        if(JSON.parse(data[key]).Message.includes('Fail')){
                            if(apiErrMsg != ''){
                                apiErrMsg = apiErrMsg +', ';
                            }
                            apiErrMsg = apiErrMsg + 'Health Returns';
                        }
                        else{
                            healthArray = JSON.parse(data[key]).Response;
                            if(healthArray){
                                healthArray.forEach((item) => {
                                    if(this.account.MMI_Customer_ID__c == item.vchClientCode){
                                        this.heathRetrn = item;
                                        this.healthFlag = true;
                                        this.balanceHR = this.heathRetrn.TotalHealthReturnsTM - this.heathRetrn.TotalHealthReturnsTMBurnt;
                                    }
                                })
                            }
                        }
                    }
                    //For Fitness assessment
                    if(key == 'Fitness Assessment' && data[key]){
                        if(JSON.parse(data[key]).Message.includes('Fail')){
                            if(apiErrMsg != ''){
                                apiErrMsg = apiErrMsg +', ';
                            }
                            apiErrMsg = apiErrMsg + 'Health Assessment';
                        }
                        else{
                            fitnessArray = JSON.parse(data[key]).Response;
                            if(fitnessArray){
                                fitnessArray.forEach((item) => {
                                    if(this.account.MMI_Customer_ID__c == item.vchClientCode){
                                        this.fitnessData = item;   
                                        this.fitnessFlag = true;                 
                                    }
                                })
                            }
                        }
                    }
                    //for App registration details
                    if(key == 'AppRegDetails' && data[key]){
                        if(JSON.parse(data[key]).Message.includes('Fail')){
                            if(apiErrMsg != ''){
                                apiErrMsg = apiErrMsg +', ';
                            }
                            apiErrMsg = apiErrMsg + 'App Registration Details';
                        }
                        else{
                            this.addDownloadStatus = JSON.parse(data[key]).AppRegDetails.IsAppDowloaded;
                        }
                    }
                }
                if(apiErrMsg != ''){
                    this.showNotification('error', 'Error!', this.label.toastErrorMsg + ' : ' + apiErrMsg);
                }
                if(this.apiList && renCheckhArray){
                    if(this.apiList.includes('Renewal Check')){                
                        renCheckhArray.forEach((item) => {
                            if(this.oppRec.Policy_Number__c == item.Policy_number){
                                this.renewalAPIData = item;
                                this.autoDebitFlag = this.renewalAPIData.AutoDebitFlag;
                                this.sumInsusedEnhancement = this.renewalAPIData.Upsell_Flag == 'Yes' ? this.renewalAPIData.Upsell_SumInsured : '';
                            }
                        })
                    }
                    else if (this.apiList.includes('Renewal Group Check')){
                        renCheckhArray.forEach((item) => {
                            if(this.oppRec.Policy_Number__c == item.Certificate_number){
                                this.renewalAPIData = item;
                                this.autoDebitFlag = this.renewalAPIData.Auto_Debit;
                            }
                        })
                    }
                    this.renewalCheckFlag = this.renewalAPIData ? true : false;
                } 
                
    }    

    getNomiteeDetails(){

        getNomineesClaims({ policyId : this.policyId }).then(result => {
            if(result){
                if(result.Claims__r){
                    this.claimsCounts = result.Claims__r.length;
                }
                
                if(result.PolicyNumber__r){
                    if(result.PolicyNumber__r.length > 0){
                        this.nomineeContacts = result.PolicyNumber__r[0].NomineeContactNumber__c;
                        this.nomineesNames = result.PolicyNumber__r[0].Name;
                    } 

                    result.PolicyNumber__r.forEach((item) => {
                        
                        if(item.NomineeContactNumber__c && this.nomineeContacts != item.NomineeContactNumber__c){
                            this.nomineeContacts = this.nomineeContacts + ', ' + item.NomineeContactNumber__c;
                        }
                        if(item.Name && this.nomineesNames != item.Name){
                            this.nomineesNames = this.nomineesNames + ', ' + item.Name;
                        }
                    });
                }
            }
        }).catch(error => {
            console.error('Error getting Nominee details', error.message);
        });

    }

    //////////////////////////////////Private methods//////////////////////////////////////////////////

    getISTDateFormat(theDate){
        if(theDate){
            return String(theDate.getDate()+'/'+(theDate.getMonth() + 1) +'/'+theDate.getFullYear())
        }
        return '';
    }
    
    showNotification(type, titleMsg, errMsg){
        const evt = new ShowToastEvent({
            title: titleMsg,
            message: errMsg,
            variant: type,
            mode:  'dismissible'
          });
          this.dispatchEvent(evt);
    }

    get sumInsuredFlag(){
        return this.policy.Sum_Assured__c ? true : false;
    }

    get lastYearPremFlag(){
        return this.policy.GrossPremium__c ? true : false;
    }

    get renCheckNetPremFlag(){
        return this.renewalCheckFlag && this.renewalAPIData.premium.Renewal_Net_Premium ? true : false;
    }

    get renCheckGrossPremFlag(){
        return this.renewalCheckFlag && this.renewalAPIData.premium.Renewal_Gross_Premium ? true : false;
    }
}
