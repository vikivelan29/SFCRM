/* Component Name : ASF_CurrentHoldings
** Description:This is the  component for Product Listing Table
** Author : Salesforce
** Created Date : Oct 26, 2023
*/
import { LightningElement ,track,api,wire} from 'lwc';
import FORM_FACTOR from '@salesforce/client/formFactor'
import ASF_SRButtonName from '@salesforce/label/c.ASF_SRButtonName';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import FA_Mandatory from '@salesforce/label/c.FA_Mandatory';
import WithoutFA from '@salesforce/label/c.ASF_CreateSRwithoutFA';
import WithFA from '@salesforce/label/c.ASF_CreateSRwithFA';


const actions = [
    { label: 'Show details', name: 'show_details' },
];

export default class Asf_CurrentHoldings extends LightningElement {
    @api recordId;
    @api selectedRow;
    @api prodName;
    @api accNumber;
    assetDisplay='';
    @api showTable = false;
    @api isCurrent = false;
    @api withoutAsset = false;
    value = 'Accounts';
    assetType= 'CASA';
    menuItems;
    options=[];
    detailJson;
    label = {
        //ksc_LaunchCreateCaseFlow,
        ASF_SRButtonName
    };
    lstProductType = [];
    showSpinner = false;
    isDesktop = true;
    strErrorMsg = 'An unexpected error occured. Please connect with your System Administrator.';
    
    FA_Mandatory = FA_Mandatory;
    @track selectedAssetId;
    showCreateCaseModal = false;
    assetId;
    withFALabel = WithFA;
    withoutFALabel = WithoutFA;
    showAssetTableForLob = true;

    
    
     /****************************************************
     * @Description - Method to the executes on page load.     
    *****************************************************/

    async connectedCallback() {
        try{
            if(FORM_FACTOR == 'Large'){
                this.isDesktop = true;
            }else{
                this.isDesktop = false;
            }
        }
        catch(error){
            this.showSpinner = false;
            this.showError = true;
            this.addErrorLog(error.message);

        }
   }
    
    /********************************************************************
     * @Description - Method to the executes on hiding of Modal.  
    *********************************************************************/

    
    hideModalCreateCase(){	
        this.showCreateCaseModal = false;
        this.withoutAsset = false;
    }	
    

    /********************************************************************
     * @Description - Method to add nebula logger on error
    *********************************************************************/
     addErrorLog(error_message) {
       console.log('Error ' + error_message);
    }

    
    showModalForCreateCaseWithOutAsset(event){	
        this.withoutAsset = true;
        this.showCreateCaseModal = true;
    }

    

    resetBox(event){
        console.log('inside ccccc')
        this.assetId = '';
        //this.template.querySelector('lightning-datatable').selectedRows=[];
        this.showCreateCaseModal = false;
    }
    
}