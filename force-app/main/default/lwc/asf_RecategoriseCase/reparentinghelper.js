import getMatchingAccount from '@salesforce/apex/ASF_RecategoriseCaseController.getMatchingAccount';
import getAccountRelatedAssets from '@salesforce/apex/ASF_CaseUIController.getMatchingContacts';
import validateAccountAndAssetWithCTST from '@salesforce/apex/ASF_RecategoriseCaseController.validateIfCurrentCTSTForAccountAndAsset';
import validateAccountAndLeadWithCTST from '@salesforce/apex/ASF_RecategoriseCaseController.validateIfCurrentCTSTForAccountAndPropect';
import updateCRN from '@salesforce/apex/ASF_CaseUIController.updateCRN';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import ABSLI_BU from '@salesforce/label/c.ABSLI_BU';
import ABSLIG_BU from '@salesforce/label/c.ABSLIG_BU';

const getCurrentCustomer = (event, parentJS) => {
    parentJS.preSelectedRows = [];
    parentJS.prestdAcctId;
    parentJS.asstData;
    parentJS.showWhenCCCEligible = false;
    parentJS.inpValue = event.target.value;
    if (parentJS.inpValue && parentJS.inpValue.length >= 2) {
        parentJS.preSelectedRows = [];
        parentJS.prestdAcctId = '';
        parentJS.asstData = [];
        SearchAccountHandler(event, parentJS);
    } else if (parentJS.inpValue.length == 0) {
        parentJS.preSelectedRows = [];
        parentJS.prestdAcctId = '';
        parentJS.asstData = [];
        parentJS.inpValue = parentJS.accountCrn;
        SearchAccountHandler(event, parentJS);
    }
};

const setSelectedAccount = async(event, parentJS) => {
    const row = event.detail.selectedRows;
    parentJS.selectedCustomer = row[0].recordId;
    parentJS.accountId = '';
    parentJS.leadId = '';
    parentJS.selectedCustomerName = row[0].name;
    parentJS.selectedCustomerClientCode = row[0].clientCode;
    parentJS.accountRecordType = row[0].objectRecordType;
    parentJS.showLANForCustomer = false;
    if (row[0].objectType == 'Customer') {
        // SHOW LAN ONLY WHEN OBJECTTYPE EQUALS CUSTOMER.
        parentJS.showLANForCustomer = true;
        parentJS.accountId = row[0].recordId;
        parentJS.isasset = 'true';
        parentJS.selectedAsset = [];
        parentJS.selectedAssetId = '';
        parentJS.assetId = '';
        parentJS.selectedLoanAccNumber = '';
        parentJS.assetLOB = '';
    }
    else if(row[0].objectType == 'Prospect'){
        parentJS.leadId = row[0].recordId;
        parentJS.selectedCustomerName = row[0].name;
        parentJS.selectedCustomerClientCode = row[0].clientCode;
        parentJS.accountRecordType = '';
        parentJS.selectedAsset = [];
        parentJS.selectedAssetId = '';
        parentJS.assetId = '';
        parentJS.selectedLoanAccNumber = '';
        parentJS.assetLOB = '';
    }

    await getAccountRelatedAssets({
        accountId: parentJS.selectedCustomer
    })
        .then(result => {
            parentJS.asstData = result.asstList;
            parentJS.initialRecords = result.asstList;
            //console.log('asset data--' + JSON.stringify(parentJS.asstData));
            if(parentJS.asstData.length <=0){
                // CODE TO CHECK IF THE CUSTOMER IS NOT HAVING ASSET, THEN IF THE CURRENT CTST IS ELIGIBLE FOR UPDATE OR NEED RECATEGORISATION.
                validateIfCustomerOrProspectValid(event,parentJS);
            }
        })
        .catch(error => {
        });

}

const setSelectedAsset= async (event,parentJS)=>{
    const row = event.detail.selectedRows;
    parentJS.selectedAsset = row[0];
    parentJS.selectedAssetId = row[0].Id;
    parentJS.assetId = row[0].Id;
    if(parentJS.businessUnit === ABSLI_BU || parentJS.businessUnit === ABSLIG_BU){
        parentJS.selectedLoanAccNumber = row[0].Policy_No__c;
    }else{
        parentJS.selectedLoanAccNumber = row[0].LAN__c;
    }
    parentJS.assetLOB = row[0].LOB__c;
    //console.log('sekectd asset--'+JSON.stringify(parentJS.selectedAsset));
    if(parentJS.selectedAsset != undefined && parentJS.selectedAsset != null){
        // CHECK IF THE ASSET IS ELIGIBLE FOR THE CURRENT CTST.
         await validateAccountAndAssetWithCTST({
            accountId : parentJS.selectedCustomer,
            assetId : parentJS.selectedAsset.Id,
            cccId : parentJS.originalCCCValue
        })
        .then(result=>{
            parentJS.showWhenCCCEligible = result;
            parentJS.showWhenCCCNotEligible = !result;
        })
        .catch(error=>{
            parentJS.showWhenCCCEligible = false;
            parentJS.showWhenCCCNotEligible = false;
        })
    }
}



const SearchAccountHandler = (event, parentJS) => {
    getMatchingAccount({
        userInp: parentJS.inpValue,
        accPreSelected: false,
        currentCaseId : parentJS.recordId
    })
        .then(result => {
            parentJS.accData = result;
        })
        .catch(error => {
        });
}

const updateAccountAndAssetOnCase=async (event,parentJS)=>{
    //console.log(parentJS.selectedCustomer);
    let assetVal = null;
    if(parentJS.selectedAsset && parentJS.selectedAsset != null){
        assetVal = parentJS.selectedAsset.Id;
    }
    parentJS.loaded = false;
    await updateCRN({
        accountId: parentJS.selectedCustomer,
        assetId: assetVal,
        caseId: parentJS.recordId,
        faNumber: parentJS.selectedLoanAccNumber,
        reqFromRecat: true
    })
        .then(result => {
            parentJS.loaded = true;
            const event = new ShowToastEvent({
                title: 'Success',
                message: 'SR updated',
                variant: 'success',
                mode: 'dismissable'
            });
            parentJS.dispatchEvent(event);
            parentJS.dispatchEvent(new CloseActionScreenEvent());

            getRecordNotifyChange([{ recordId: parentJS.recordId }]);

            let payload = {'source':'recat', 'recordId':this.recordId};
            fireEventNoPageRef(this.pageRef, "refreshpagepubsub", payload); 

            setTimeout(() => {
                eval("$A.get('e.force:refreshView').fire();");
            }, 1000);
        })
        .catch(error => {
            parentJS.loaded = true;
            let errorMsg = 'Error updating the record.';
            if(error != undefined){
                if(error.body != undefined){
                    if(error.body.pageErrors != null){
                        let errMsg = error.body.pageErrors[0].message;
                        const event = new ShowToastEvent({
                            title: 'Error',
                            message: errMsg,
                            variant: 'error',
                            mode: 'dismissible'
                        });
                        parentJS.dispatchEvent(event);
                    }
                }
            }
            
        });

}

const validateIfCustomerOrProspectValid = async(event, parentJS) => {
    let customerORprospectId = parentJS.selectedCustomer;
    let originalCCC = parentJS.originalCCCValue;


    await validateAccountAndLeadWithCTST({recordId : customerORprospectId, cccId : originalCCC})
    .then(result =>{
        parentJS.showWhenCCCEligible = result;
        parentJS.showWhenCCCNotEligible = !result;
    })
    .catch(error =>{
        parentJS.showWhenCCCEligible = false;
        parentJS.showWhenCCCNotEligible = false;
    })

} 


export { getCurrentCustomer, setSelectedAccount,setSelectedAsset,updateAccountAndAssetOnCase };