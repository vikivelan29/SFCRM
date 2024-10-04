import { LightningElement, wire, api, track } from 'lwc';

import getOppRec from '@salesforce/apex/RNWL_RenewalCustomerPolicyInfo.getOppRec';
import getNomineesClaims from '@salesforce/apex/RNWL_RenewalCustomerPolicyInfo.getNomineesClaims';
import getResponseFromFiles from '@salesforce/apex/RNWL_NonIndAccountRenewalController.getResponseFromFiles';


export default class RNWL_RenewalPolicyDetails extends LightningElement {

    @api recordId;policyId;
    @track account; policy; oppRec;
    @track areDetailsVisible = false; renewalCheckFlag = false; nominees = [];
    error;
    @track nomineeContacts; nomineesNames; claimsCounts; isPolicyRenewed;
    @track maturityDate; policyLapseDate; policyLapsed; policyStartDate; dateOfBirth;
    @track polRenewalNoticeDay;graceEndDate;graceStartDate; renStatus;
    @track renewalAPIData; apiType = 'Renewal Check'; goGreenFlag; isChronic;
    @track autoDebitFlag; sumInsusedEnhancement; netPremium; grossPremium;

    @wire(getOppRec, {recordId: '$recordId'})
    record({ error, data}){
        if(data){ 
            this.oppRec = data;
            this.account = data.Account;
            this.policy = data.Policy__r;
            this.areDetailsVisible = true;
            this.policyId = this.oppRec.Policy__c;

            this.dateOfBirth = this.getISTDateFormat(new Date(this.account.PersonBirthdate));
            this.policyStartDate = this.getISTDateFormat(new Date(this.policy.Issue_Date__c));
            this.maturityDate = this.getISTDateFormat(new Date(this.policy.Maturity_Date__c));

            if(this.policy.Maturity_Date__c != null){
                var matDate = new Date(this.policy.Maturity_Date__c);
                this.policyLapseDate = this.getISTDateFormat(new Date(matDate.setDate(matDate.getDate() + 30)));
            }    
            
            this.graceStartDate = this.getISTDateFormat(new Date(this.oppRec.Grace_Period_Start__c));
            this.graceEndDate = this.getISTDateFormat(new Date(this.oppRec.Grace_Period_End__c));
            this.polRenewalNoticeDay = this.getISTDateFormat(new Date(this.oppRec.Policy_Renewal_Notice_Day__c));   
            this.goGreenFlag = this.policy.GoGreen__c;
            this.isChronic = this.account.Is_Chronic__c;
            this.renStatus = this.oppRec.Status__c == 'Renewed' ? 'Payment Received' : 'In Progress';
            this.isPolicyRenewed = this.oppRec.Status__c == 'Renewed' ? 'Yes' : 'No';
            if(this.account.RecordType.Name == 'Non-Individual'){
                this.apiType = 'Renewal Group Check';
            }
            this.getNomiteeDetails();

            this.error = undefined;
        }else{
            this.oppRec = undefined;
            this.error = error; 
        } 
    }

    @wire(getResponseFromFiles, {opportunityId:'$recordId', fileSourceAPI:'$apiType'})
    renewalCheck({error, data}){
        if(data){
            let renData = JSON.parse(data);
            this.renewalAPIData = renData.response.policyData[0];
            this.renewalCheckFlag = true;

            if(this.apiType == 'Renewal Check'){
                this.autoDebitFlag = this.renewalAPIData.AutoDebitFlag;
                this.sumInsusedEnhancement = this.renewalAPIData.Upsell_Flag == 'Y' ? this.renewalAPIData.Upsell_SumInsured : '';
                this.netPremium = this.renewalAPIData.Renewal_Net_Premium;
                this.grossPremium = this.renewalAPIData.Renewal_Gross_Premium;
            }
            else if(this.apiType == 'Renewal Group Check'){
                this.autoDebitFlag = this.renewalAPIData.Auto_Debit;
                this.netPremium = this.renewalAPIData.NetPremium;
                this.grossPremium = this.renewalAPIData.AnnualPremium;
            }
            this.error = undefined;
        }
        if(error){
            this.error = error;
        }
    }

    get isRenewalCheckAPI(){
        return this.renewalCheckFlag && this.apiType == 'Renewal Check';
    }

    get isRenewalGrpAPI(){
        return this.renewalCheckFlag && this.apiType == 'Renewal Group Check';
    }

    getISTDateFormat(theDate){
        return String(theDate.getDate()+'/'+(theDate.getMonth() + 1) +'/'+theDate.getFullYear())
    }

    splitAddressStreet(streetStr){

        var streetArr = streetStr.split(',');
        if(streetArr.length > 0){
            return streetArr;
        }
        return '';
    }

    getNomiteeDetails(){

        getNomineesClaims({ policyId : this.policyId }).then(result => {

            this.claimsCounts = result.Claims__r.length;
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
        }).catch(error => {
            console.error('Error adding contact', error);
        });

    }

}