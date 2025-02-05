import { LightningElement,api,track } from 'lwc';
import getSocialMediaProfileResponse from '@salesforce/apex/ABSLAMC_SprinklrSocialMediaProfileCtrl.getSocialMediaProfileResponse';

const profileColumns = [
    { label: 'Social Media Platform', fieldName: 'Social_Media_Platform', type: 'text' },
    { label: 'Customer Name on Platform', fieldName: 'Customer_Name_on_Platform', type: 'text' },
    { label: 'Social Media Handle', fieldName: 'Social_Media_Handle', type: 'text' },
    { label: 'No. of Followers', fieldName: 'No_of_Followers', type: 'number'}
  
];

export default class Abamc_getSprinklrSocialMediaProfile extends LightningElement {

    @api recordId;
    @track profileData = [];
    loading = true;
   // showTable = false;
    profileColumns = profileColumns;
    noProfileData = false;

    connectedCallback() {
        this.loading = true;
        this.fetchProfileData();
    }

    async fetchProfileData(){
        console.log('RecordId:'+this.recordId);
        this.loading = true;
        try{
            const response = await getSocialMediaProfileResponse({ accId: this.recordId });
            console.log('Resp: '+JSON.stringify(response));
            if (response && response.isSuccess) {
                let parsedData = JSON.parse(response.responseBody).ReturnData.map(item => ({
                    'Social_Media_Platform': item.channelType,
                    'Customer_Name_on_Platform': item.name,
                    'Social_Media_Handle': item.channelId,
                    'No_of_Followers': item.followers
                }));
                if (!parsedData || parsedData.length === 0) {
                    this.noProfileData = true; 
                } else {
                this.profileData = parsedData;
               // this.showTable = true;
                }
        }
        
    }
    catch (error) {
        console.error('Error fetching Profile data:', error);
    } finally {
        this.loading = false;
    }

}
}