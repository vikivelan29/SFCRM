import { LightningElement, api, wire } from 'lwc';
import RNWL_Seller_Portal_Link from '@salesforce/label/c.RNWL_Seller_Portal_Link';
import RNWL_Product_Features from '@salesforce/label/c.RNWL_Product_Features';
import getAutoCalculationLink from '@salesforce/apex/RNWL_HelpLinksController.getAutoCalculationLink';

export default class RNWL_HelpLinks extends LightningElement {
    @api recordId;
    autoCalculationLink = '';
    label = {
        RNWL_Seller_Portal_Link,
        RNWL_Product_Features
    };

    @wire(getAutoCalculationLink,{recordId: '$recordId'})
    getCustomLink({error,data}){
        console.log('@@data'+data)
        if(data){
            this.autoCalculationLink = data;
        }
        else if(error){
            console.log(error);
        }
    }

}