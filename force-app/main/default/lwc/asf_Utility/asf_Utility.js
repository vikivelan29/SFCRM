import getCaseRelatedObjNameApex from '@salesforce/apex/ASF_CaseUIController.getCaseRelatedObjName';
import { createRecord, updateRecord } from 'lightning/uiRecordApi';
import updateCase from '@salesforce/apex/ASF_CaseUIController.updateCase';
import createCaseExtension from '@salesforce/apex/ASF_CaseUIController.createCaseExtension';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { reduceErrors } from 'c/asf_ldsUtils';

//Fields
import CASE_OBJECT from '@salesforce/schema/Case';
import ASSETID_FIELD from '@salesforce/schema/Case.AssetId';
import STAGE_FIELD from '@salesforce/schema/Case.Stage__c';
import ID_FIELD from '@salesforce/schema/Case.Id';
import CCC_FIELD from '@salesforce/schema/Case.CCC_External_Id__c';
import TYPETXT_FIELD from '@salesforce/schema/Case.Type_Text__c';
import SUBTYPETXT_FIELD from '@salesforce/schema/Case.Sub_Type_Text__c';
import SUBJECT_FIELD from '@salesforce/schema/Case.Subject';
import CASE_CONTACT_FIELD from '@salesforce/schema/Case.ContactId';
import CASE_STAGE_FIELD from '@salesforce/schema/Case.Stage__c';
import CASE_REJECTFLAG from '@salesforce/schema/Case.Reject_Case__c';
import CASE_STATUS_FIELD from '@salesforce/schema/Case.Status';
import REJECTION_DETAILS from '@salesforce/schema/Case.Rejected_Reason__c';
import REJECTION_REASON from '@salesforce/schema/Case.Rejection_Reason__c';
import NATURE_FIELD from '@salesforce/schema/Case.Nature__c';
import NOAUTOCOMM_FIELD from '@salesforce/schema/Case.No_Auto_Communication__c';
import FTR_FIELD from '@salesforce/schema/Case.FTR__c';
import CHANNEL_FIELD from '@salesforce/schema/Case.Channel__c';
//import PRODUCT_FIELD from '@salesforce/schema/Case.Product__c';
import SOURCE_FIELD from '@salesforce/schema/Case.Source__c';
import TECHNICAL_SOURCE_FIELD from '@salesforce/schema/Case.Technical_Source__c';
import CASE_BUSINESSUNIT from '@salesforce/schema/Case.Business_Unit__c';
import BSLI_ISSUE_TYPE from '@salesforce/schema/Case.Issue_Type__c';
//import CASE_PRODUCT_FIELD from '@salesforce/schema/Case.Product_Name__c';

//import SR_CATEGORY from '@salesforce/schema/Case.SR_Category__c';
//import COMP_LEVEL from '@salesforce/schema/Case.Complaint_Level__c';
//import SUB_SOURCE from '@salesforce/schema/Case.Sub_source__c';
import NEW_STAGE from '@salesforce/schema/Case.New_Stage_email_sent__c';
//import CASE_ORIGIN from '@salesforce/schema/Case.Origin__c';
import TRANSACTION_NUM from '@salesforce/schema/PAY_Payment_Detail__c.Txn_ref_no__c';
import BSLI_CATEGORY_TYPE from '@salesforce/schema/ABSLI_Case_Detail__c.Complaint_Category__c';
import POLICY_NO from '@salesforce/schema/ABSLIG_Case_Detail__c.Policy_ID__c';
import ABSLI_BU from '@salesforce/label/c.ABSLI_BU';

// VIRENDRA - ADDED FOR PROSPECT REQUIREMENT.
import CASE_PROSPECT_ID from '@salesforce/schema/Case.Lead__c';
import CASE_FROM_PREFRAMEWORK_TO_FRAMEWORK from '@salesforce/schema/Case.Preframework_to_Framework_FromUI__c';

import * as validator from 'c/asf_CreateCaseValidations';

export class asf_Utility {

     createRelObjJS(selected,source,recTypeId,rejectDetails,contact,parentJS) {
        console.log('##1111##'+JSON.stringify(selected));
        if(!parentJS.rejectCase){
            getCaseRelatedObjNameApex({cccId : selected.CCC_External_Id__c})
            .then(async result => {
                var caseRelObjName = result;
                console.log('##rel obj name##'+JSON.stringify(caseRelObjName)+'issue type-'+parentJS.issueTypeVal);
                const fields = {};
                if(parentJS.isTransactionRelated){
                    fields[TRANSACTION_NUM.fieldApiName] = parentJS.transactionNumber;
                }
                if(parentJS.policyNoValue){
                    fields[POLICY_NO.fieldApiName] = parentJS.policyNoValue;
                }
                if(parentJS.categoryTypeVal){
                    fields[BSLI_CATEGORY_TYPE.fieldApiName] = parentJS.categoryTypeVal;
                }
                let cccRecToPass = {...selected};
                cccRecToPass['sobjectType'] = 'ASF_Case_Category_Config__c';

                const caseExtnRecord = { sobjectType: caseRelObjName, ...fields };
                let caseExtensionRecordId = await createCaseExtension({
                    record : caseExtnRecord,
                    cccRec: cccRecToPass,
                    caseId: parentJS.recordId,
                    extnFieldName: caseRelObjName
                }).catch(error=>{
                    console.error(error);
                });
                
                let retObj = {objName : caseRelObjName, caseExtRecId : caseExtensionRecordId};
                this.setFields(selected,retObj,source,recTypeId,rejectDetails,contact,parentJS);
                
                // createRecord(caseRecord)
                // .then(result => {
                //  console.log('##2222##'+JSON.stringify(selected));
                //     var caseExtensionRecordId = result.id;
                //     var retObj = {objName : caseRelObjName, caseExtRecId : caseExtensionRecordId};
                //     console.log('##b##'+JSON.stringify(retObj));
                    
                //     this.setFields(selected,retObj,source,recTypeId,rejectDetails,contact,parentJS);
                // })
                // .catch(error => {
                //     console.log('Error2: '+JSON.stringify(error));
                // })
            })
            .catch(error =>{
                console.log('Error1: '+JSON.stringify(error));
            });
        }else{
            this.setFields(selected,null,source,recTypeId,rejectDetails,contact,parentJS);
        }
       
   }

    setFields(selected,retObj,source,recTypeId,rejectDetails,contact,parentJS){
       const fields = {};
        var caseRelObjName;

        if(!parentJS.rejectCase){       
            fields[STAGE_FIELD.fieldApiName] = selected.First_Stage__c;
            caseRelObjName = retObj.objName;
            if(caseRelObjName){
                fields[caseRelObjName] = retObj.caseExtRecId;
            }
        }

        fields[ID_FIELD.fieldApiName] = parentJS.recordId;
        fields[NEW_STAGE.fieldApiName] = true;
        if(parentJS.noAutoCommValue){
            fields[NOAUTOCOMM_FIELD.fieldApiName] = parentJS.noAutoCommValue.join(';');
        }
        if(parentJS.ftrValue){
            fields[FTR_FIELD.fieldApiName] = parentJS.ftrValue;
        }
        if(parentJS.businessUnit === ABSLI_BU && parentJS.strChannelValue){
            fields[CHANNEL_FIELD.fieldApiName] = parentJS.strChannelValue;
        }
        if(parentJS.businessUnit === ABSLI_BU && parentJS.issueTypeVal != null){
            fields[BSLI_ISSUE_TYPE.fieldApiName] = parentJS.issueTypeVal;
        }

       if(!parentJS.rejectCase){
        if(source != 'Email'){
           fields[SUBJECT_FIELD.fieldApiName] = 'Case - '+selected.Type__c;
        }
       }
           fields[CCC_FIELD.fieldApiName] = selected.CCC_External_Id__c;
           fields[TYPETXT_FIELD.fieldApiName] = selected.Type__c;
           fields[SUBTYPETXT_FIELD.fieldApiName] = selected.Sub_Type__c;
       
       fields[NATURE_FIELD.fieldApiName] = parentJS.natureVal;
       //fields[PRODUCT_FIELD.fieldApiName] = parentJS.productVal;
       //fields[SOURCE_FIELD.fieldApiName] = source;
       //fields[CASE_ORIGIN.fieldApiName] = parentJS.originValue;
       fields[TECHNICAL_SOURCE_FIELD.fieldApiName] = 'LWC';
       fields[CASE_BUSINESSUNIT.fieldApiName] = parentJS.businessUnitValue; 
       fields[ASSETID_FIELD.fieldApiName] = parentJS.assetId;
       //fields[CASE_PRODUCT_FIELD.fieldApiName] = parentJS.assetProductName; 
       if(!parentJS.closeCase && !parentJS.rejectCase){
            fields['recordTypeId'] = recTypeId;
            fields[CASE_FROM_PREFRAMEWORK_TO_FRAMEWORK.fieldApiName] = true;
       }
           
           
       if(parentJS.closeCase){
           fields[CASE_STAGE_FIELD.fieldApiName] = 'Resolved';
           fields[CASE_STATUS_FIELD.fieldApiName] = 'Resolved'; 
       }
       if(parentJS.rejectCase){
           fields[CASE_REJECTFLAG.fieldApiName] = true; 
           fields[REJECTION_DETAILS.fieldApiName] = rejectDetails;
           fields[REJECTION_REASON.fieldApiName] = parentJS.selectedReason;
       }
       if(parentJS.complaintSelected){
            //fields[SR_CATEGORY.fieldApiName] = parentJS.selectedSRCategory;            
       }
       if(selected && selected.hasOwnProperty("Complaint_Level__c")){
            if(parentJS.subsourceSelected){
                //fields[SUB_SOURCE.fieldApiName] = parentJS.subsourceSelected;
            }
                

            //fields[COMP_LEVEL.fieldApiName] = selected['Complaint_Level__c'];
        }else{
        //fields[COMP_LEVEL.fieldApiName] = 'L1';
        }
       
       if(contact){
           fields[CASE_CONTACT_FIELD.fieldApiName] = contact;
       }

       // VIRENDRA - ADDED FOR PROSPECT REQUIREMENT - 
       if(parentJS.prospectRecId != undefined && parentJS.prospectRecId != null && parentJS.prospectRecId != ''){
        fields[CASE_PROSPECT_ID.fieldApiName] = parentJS.prospectRecId;
       }
       // VIRENDRA - END PROSPECT HERE.
       console.log('####Fields##'+JSON.stringify(fields));
       this.updateCaseJS(fields,parentJS, selected);
   }

    async updateCaseJS(fields,parentJS, selected){
        if(selected.Validation_method_during_creation__c){
            const caseRecordForValidation = { apiName: CASE_OBJECT.objectApiName, fields: fields };
            console.log('invoing validator'+JSON.stringify(caseRecordForValidation));
            let methodName = selected.Validation_method_during_creation__c;
            let validationResult = await validator[methodName](caseRecordForValidation);
            console.log('returned with dynamic method '+JSON.stringify(validationResult));
            if(validationResult.isSuccess == false){
                parentJS.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Oops! Validation error occured',
                        message: validationResult.errorMessageForUser,
                        variant: 'error'
                    }),
                );
                parentJS.loaded = true;
                parentJS.isNotSelected = true;
                parentJS.createCaseWithAll = false;
                return;
            }
            console.log('ending validator');
        }
       const caseRecord = JSON.stringify(fields);
       updateCase({fields:caseRecord,isAsset:parentJS.withoutAsset})
           .then(result => {   
                
            parentJS.caseRecordId = result.Id;
               parentJS.dispatchEvent(
                   new ShowToastEvent({
                       title: 'Success',
                       message: 'SR Updated ',
                       variant: 'success',
                   }),
               );
               parentJS.loaded = true;
               
               parentJS.navigateToRecordEditPage(result.Id);
                 
               
           })
           .catch(error => {
            console.log('error.body.message:'+JSON.stringify(error));
            let errMsg = reduceErrors(error);
            console.log('errMsg:'+errMsg);
            let errConcat='';
            for(let i of errMsg){
                errConcat = errConcat+i+' ';
            }
            parentJS.dispatchEvent(
                   new ShowToastEvent({
                       title: 'Error Updating record',
                       message: errConcat,
                       variant: 'error',
                   }),
               );
               parentJS.loaded = true;
               parentJS.isNotSelected = true;
               parentJS.showRejetedReason = false;
           })   
   } 

}
