import { LightningElement,api } from 'lwc';
const columns = [
                    {
                        fieldName: 'policyType',
                        label: 'Policy Type',
                        type: 'text'
                    },
                    {
                        fieldName: 'insurerName',
                        label: 'Insurer Name',
                        type: 'text'
                    },                    
                    {
                        fieldName: 'policyAmount',
                        label: 'Policy Amount',
                        type: 'currency'
                    },
                    {
                        fieldName: 'dateofPurchase',
                        label: 'Date of Purchase',
                        type: 'date',
                        typeAttributes: {
                            day: "2-digit",
                            month: "2-digit",
                            year: "numeric",
                            day: "2-digit",
                            hour: "2-digit",
                            minute: "2-digit",
                            second:"2-digit"
                        }
                    },
                    {
                        fieldName: 'vehicleNumber',
                        label: 'Vehicle No',
                        type: 'text'
                    },
                    {
                        fieldName: 'premiumAmountWithGST',
                        label: 'Premium Amount',
                        type: 'currency'
                    },
                    {
                        fieldName: 'vehicleType',
                        label: 'Vehicle Type',
                        type: 'text'
                    }
                ];
export default class AbcdMotorInsuranceDetails extends LightningElement {
    @api midetails;
    columns = columns;
    @api status;
    @api apiMessage;
    get displayError(){
        if(this.status != 'Success'){
            return true;
        }
        return false;
    }

    get displayNoData() {
        return this.status === 'Success' && (!this.midetails || this.midetails.length === 0 || this.midetails == null);
    }
}
