import { LightningElement, wire,api } from 'lwc';
import getPolicyData from '@salesforce/apex/AssetGetPolicyDetails.getAssetData';

export default class Mcrm_getPolicyDetails extends LightningElement {
    columns = [];
    data = [];
    error;
    @api recordId;
    @wire(getPolicyData, { recordId: '$recordId' })
    wiredPolicyData({ data, error }) {
        if (data) {
            this.data = data;

            // Get the keys from the first map entry to create dynamic columns
            if (data.length > 0) {
                this.columns = Object.keys(data[0]).map(key => {
                    return { label: key, fieldName: key };
                });
            }

            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.data = [];
        }
    }
}