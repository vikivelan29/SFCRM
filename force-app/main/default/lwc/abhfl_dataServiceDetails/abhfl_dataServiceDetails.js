import { LightningElement, track, api } from 'lwc';
import fetchSections from '@salesforce/apex/ABHFL_DataServiceClass.fetchSections';

export default class Abhfl_dataServiceDetails extends LightningElement {

    @api recordId;
    sectionClosed = true;
    @track activeOuterSections =[];
    @track activeInnerSections=[];
    @track innerSections = [];
    @track outerSections = [];
    @track outerFieldsData = [];
    @track innerFieldsData = [];
    @track fieldsInOuterColumn1 = [];
    @track fieldsInOuterColumn2 = [];
    @track fieldsInInnerColumn1 = [];
    @track fieldsInInnerColumn2 = [];
    ifCusAndAcc = false;
    isLoading = false;
    receivedResponse=true;
    noResponseFromServer = '';

    getDataServiceDetails(){
        this.innerSections = [];
        this.outerSections = [];
        this.sectionClosed = true;
        this.ifCusAndAcc = false;
        this.isLoading = true;
        fetchSections({assetId:this.recordId})
            .then((result)=>{
                if(result && result.length>0){
                    for(let i of [...result]){
                        if(i.type=='Outer'){
                            this.outerSections.push(i);
                        }
                        else if(i.type=='Inner'){
                            this.innerSections.push(i);
                        }
                    }
                    console.log('result length:'+result.length);
                    if(result.length==1){
                        this.activeOuterSections = result[0].sectionName;
                    }
                }else{
                    this.receivedResponse = false;
                    this.noResponseFromServer = 'Could not get details. Please try again later.';
                }
                this.sectionClosed = false;
                this.isLoading = false;
            })
            .catch((error)=>{
                this.sectionClosed = true;
                this.isLoading = false;
                console.error('Error in fetching data:'+JSON.stringify(error));
            })
    }

    handleToggleSection(event){
        this.outerFieldsData = [];
        this.isLoading = true;
        if(event.detail.openSections.includes('customerAndAccountDetails')){
            this.ifCusAndAcc = true;
        }else{
            this.ifCusAndAcc = false;
        }
        if(event.detail.openSections.length>0){
            let selectedSection = this.outerSections.find(record=>event.detail.openSections.includes(record.sectionName));
            if(selectedSection.tabular==false && selectedSection.sectionFieldsMap){
                let fields = selectedSection.sectionFieldsMap;
                for(let key in fields){
                    this.outerFieldsData.push({fieldName:key,label:key,value:fields[key]});
                }
                this.fieldsInOuterColumn1 = this.outerFieldsData.slice(0, Math.ceil(this.outerFieldsData.length / 2));
                this.fieldsInOuterColumn2 = this.outerFieldsData.slice(Math.ceil(this.outerFieldsData.length / 2));        
            }
        }
        this.isLoading = false;
    }

    handleToggleSectionInner(event){
        this.innerFieldsData = [];
        this.isLoading = true;
        if(event.detail.openSections.length>0){
            let selectedSection = this.innerSections.find(record=>event.detail.openSections.includes(record.sectionName));
            if(selectedSection.tabular==false && selectedSection.sectionFieldsMap){
                let fields = selectedSection.sectionFieldsMap;
                for(let key in fields){
                    this.innerFieldsData.push({fieldName:key,label:key,value:fields[key]});
                }
                this.fieldsInInnerColumn1 = this.innerFieldsData.slice(0, Math.ceil(this.innerFieldsData.length / 2));
                this.fieldsInInnerColumn2 = this.innerFieldsData.slice(Math.ceil(this.innerFieldsData.length / 2))
            }
        }
        this.isLoading = false;
    }

}