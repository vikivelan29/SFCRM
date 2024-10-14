import { LightningElement } from 'lwc';
import RNWL_Seller_Portal_Link from '@salesforce/label/c.RNWL_Seller_Portal_Link';
import RNWL_Product_Features from '@salesforce/label/c.RNWL_Product_Features';
import RNWL_Auto_Calculation from '@salesforce/label/c.RNWL_Auto_Calculation';

export default class RNWL_HelpLinks extends LightningElement {
    label = {
        RNWL_Seller_Portal_Link,
        RNWL_Product_Features,
        RNWL_Auto_Calculation
    };
}