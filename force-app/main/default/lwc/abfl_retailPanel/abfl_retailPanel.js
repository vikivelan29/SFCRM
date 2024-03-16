import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { getRecord } from "lightning/uiRecordApi";
import invokeAPI from '@salesforce/apex/ABFL_RetailController.invokeAPI';

import errorMessage from '@salesforce/label/c.ASF_ErrorMessage';

const FIELDS = ["Asset.Source_System__c", "Asset.LAN__c", "Asset.Account.PAN__c"];

const itemLeftList = [
    {
        label: 'Loan Details',
        name: 'RTL_RealTime_LoanDetails'
    },
    {
        label: 'Basic Customer Info',
        name: 'RTL_RealTime_BasicCustInfo'
    }
];
const itemRightList = [
    {
        label: 'GCC Property Details ',
        name: 'RTL_RealTIme_GCCPropertyDetails'
    },
    {
        label: 'Loan MIS Snapshot',
        name: 'RTL_RealTime_LoanMIS'
    },
    {
        label: 'Installment Payment Details',
        name: 'RTL_RealTime_InstallPmntDtls'
    }
];

export default class Abfl_retailPanel extends LightningElement {
    label = {
		errorMessage
	};

    @api recordId;
    isLoading = false;
    apiName = '';
    showBaseViewScreen = false;
    navItemLeftList = itemLeftList;
    navItemRightList = itemRightList;
    payloadInfo;

    @wire(getRecord, { recordId: "$recordId", fields: FIELDS })
    assetRecord;

    get isSourceSystemFINNRTL() {
        return this.assetRecord?.data?.fields?.Source_System__c?.value == 'FINNRTL' ? true : false;
    }
    get isSourceSystemA3S() {
        return this.assetRecord?.data?.fields?.Source_System__c?.value == 'A3S' ? true : false;
    }

    handleSelect(event) {
        this.showBaseViewScreen = false;
        this.payloadInfo = null;
        this.isLoading = true;

        console.log('in handleSelect');
        const selectedName = event.detail.name;
        this.apiName = selectedName;
        console.log('selected API: ' + this.apiName);

        let lan = this.assetRecord?.data?.fields?.LAN__c?.value;
        let pan = this.assetRecord?.data?.fields?.Account?.value?.fields?.PAN__c?.value;

        if(this.checkInput(this.apiName)) {
            if(this.apiName == 'RTL_RealTime_BasicCustInfo' && !this.checkInput(pan)) {
                this.showToast("Error", 'The related account does not have a valid PAN', 'error');
            } else if(this.apiName != 'RTL_RealTime_BasicCustInfo' && !this.checkInput(lan)) {
                this.showToast("Error", 'The asset does not have a valid Loan Account Number', 'error');
            } else {
                // invoke API
                invokeAPI({ apiName: this.apiName, assetId: this.recordId })
                    .then((result) => {
                        console.log('***result:'+JSON.stringify(result));

                        // Check validity of response
                        if (result?.statusCode == 200 && result?.payload) {
                            if(this.apiName == 'RTL_RealTime_LoanDetails' && JSON.parse(result.payload)?.Root?.ResponseGetLoanDetails?.DataArea?.LoanDetails?.Response?.Summary_Data) {
                                this.payloadInfo = result;
                            } else if(this.apiName == 'RTL_RealTime_BasicCustInfo' && JSON.parse(result.payload)?.ResponseGetBasicCustomerInfo?.DataArea?.BasicCustomerInfo?.Response?.Basic_Customer_Info){
                                this.payloadInfo = result;
                            } else if(this.apiName == 'RTL_RealTIme_GCCPropertyDetails' && JSON.parse(result.payload)?.ResponseGetGCCPropertyDetails?.DataArea?.GCCPropertyDetails?.Response){
                                this.payloadInfo = result;
                            } else if(this.apiName == 'RTL_RealTime_LoanMIS' && JSON.parse(result.payload)?.ResponseGetLoanMISSnapshot?.DataArea?.LoanMISSnapshot?.Response){
                                this.payloadInfo = result;
                            } else if(this.apiName == 'RTL_RealTime_InstallPmntDtls' && JSON.parse(result.payload)?.ResponseGetInstallmentPaymentDetails?.DataArea?.InstallmentPaymentDetails?.Response?.repayment_detail?.rows){
                                this.payloadInfo = result;
                            } else if(this.apiName == 'RTL_RealTime_GetCRMDetails' && JSON.parse(result.payload)?.crmapis?.length > 0){
                                this.payloadInfo = result;
                            }
                        }
                        this.isLoading = false;
                        if (this.payloadInfo) {
                            this.showBaseViewScreen = true;
                        } else {
                            console.log('error');
                            this.showToast("Error", this.label.errorMessage, 'error');
                        }
                    })
                    .catch((error) => {
                        console.log('error');
                        this.isLoading = false;
                        this.showToast("Error", this.label.errorMessage, 'error');
                    });
            }
        }
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }

    checkInput(inputParam) {
        if (inputParam !== null && inputParam !== undefined && inputParam !== '' && !Number.isNaN(inputParam)) {
            return true;
        }
        else {
            return false;
        }
    }
}