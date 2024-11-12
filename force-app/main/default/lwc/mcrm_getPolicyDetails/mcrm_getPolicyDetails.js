import { LightningElement, wire,api } from 'lwc';
import getPolicyData from '@salesforce/apex/MCRM_AssetGetPolicyDetails.getAssetData';

export default class Mcrm_getPolicyDetails extends LightningElement {
    columns = [];
    data = [];
    noRecords = false;
    
    @api recordId;
    @wire(getPolicyData, { recordId: '$recordId' })
    wiredPolicyData({ data, error }) {
        if (data) {
            console.log('data-->',data);            
            this.data = data;
            // Get the keys from the first map entry to create dynamic columns
            if (data.length > 0) {
                this.columns = Object.keys(data[0]).map(key => {
                    return { label: key, fieldName: key };
                });
            }else{
                this.noRecords=true;                
                this.error = false;
            }
            this.error = undefined;
        } else if (error) {
            this.noRecords=true;
            console.log('error-->',error);
            this.error = error;
            this.data = [];
        }
    }
}