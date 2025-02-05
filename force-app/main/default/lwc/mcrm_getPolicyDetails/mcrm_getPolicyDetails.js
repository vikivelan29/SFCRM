import { LightningElement, wire,api } from 'lwc';
import getPolicyData from '@salesforce/apex/MCRM_AssetGetPolicyDetails.getAssetData';
import MCRM_NoRecordsGetPolicyDetails from '@salesforce/label/c.MCRM_NoRecordsGetPolicyDetails';

export default class Mcrm_getPolicyDetails extends LightningElement {
    columns = [];
    data = [];
    label = {
        MCRM_NoRecordsGetPolicyDetails
    }
    @api recordId;

    get hasData() {
        return this.data && this.data.length;
    }

    @wire(getPolicyData, { recordId: '$recordId' })
    wiredPolicyData({ data, error }) {
        if (data) {
            this.data = data;
            // Get the keys from the first map entry to create dynamic columns
            if (data.length > 0) {
                this.columns = Object.keys(data[0]).map(key => {
                    return { label: key, fieldName: key };
                });
            }else{
                this.error = false;
            }
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.data = [];
        }
    }
}