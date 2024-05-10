import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { getRecord } from "lightning/uiRecordApi";
import invokeAPI from '@salesforce/apex/ABFL_EODController.invokeAPI';

import errorMessage from '@salesforce/label/c.ASF_ErrorMessage';

const FIELDS = ["Asset.LAN__c"];

const itemLeftList = [
    {
        label: 'Account Balance',
        name: 'EOD_Account_Balance'
    },
    {
        label: 'Application Details',
        name: 'EOD_Application_Details'
    }
];
const itemRightList = [
    {
        label: 'Repayment Details',
        name: 'EOD_Repayment_Details'
    },
    {
        label: 'Disbursement Details',
        name: 'EOD_Disbursement_Details'
    }
];

export default class Abfl_EODPanel extends LightningElement {
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

    handleSelect(event) {
        this.showBaseViewScreen = false;
        this.payloadInfo = null;
        this.isLoading = true;

        console.log('in handleSelect');
        const selectedName = event.detail.name;
        this.apiName = selectedName;
        console.log('selected API: ' + this.apiName);

        let lan = this.assetRecord?.data?.fields?.LAN__c?.value;

        if(this.checkInput(this.apiName)) {
            if(!this.checkInput(lan)) {
                this.showToast("Error", 'The asset does not have a valid Loan Account Number', 'error');
                this.isLoading = false;
            } else {
                // invoke API
                invokeAPI({ apiName: this.apiName, assetId: this.recordId })
                    .then((result) => {
                        console.log('***result:'+JSON.stringify(result));

                        // Check validity of response
                        if (result?.statusCode == 200 && result?.payload) {
                            if(this.apiName == 'EOD_Account_Balance') {
                                this.payloadInfo = result;
                            } else if(this.apiName == 'EOD_Application_Details'){
                                this.payloadInfo = result;
                            } else if(this.apiName == 'EOD_Repayment_Details'){
                                this.payloadInfo = result;
                            } else if(this.apiName == 'EOD_Disbursement_Details'){
                                this.payloadInfo = result;
                            }
                        }
                        this.isLoading = false;
                        if (this.payloadInfo) {
                            this.showBaseViewScreen = true;
                        } else {
                            let res = JSON.parse(result?.payload);
                            if(res?.error?.description) {
                                this.showToast("Error", res.error.description, 'error');
                            } else {
                                this.showToast("Error", this.label.errorMessage, 'error');
                            }
                        }
                    })
                    .catch((error) => {
                        console.log(JSON.stringify(error));
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