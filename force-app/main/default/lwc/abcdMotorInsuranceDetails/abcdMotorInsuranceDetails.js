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
                        type: 'text',
                        /*typeAttributes: {
                            day: "2-digit",
                            month: "2-digit",
                            year: "numeric"
                        }*/
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
}