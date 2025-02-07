import { LightningElement, api } from 'lwc';
import ABCL_LOBHoldings from "@salesforce/resourceUrl/ABCL_LOBHoldings";
export default class Abcl_cx_LOB_HoldingsSection extends LightningElement {
    hasFinanceAssets = false;
    hasHealthInsurance = false;
    hasHomeLoan = false;
    hasLifeInsurance = false;
    hasMutualFunds = false;
    hasSecurities = false;
    hasDigital = false;
    @api assetList = [];

    //Logos
    //JPG
    //abcl_FinanceLogo = `${ABCL_LOBHoldings}/ABCL_Finance.jpg`;
    //abcl_healthInsuranceLogo = `${ABCL_LOBHoldings}/ABCL_Healthinsurance.jpg`;
    //abcl_AMC = `${ABCL_LOBHoldings}/ABCL_MutualFunds.jpg`;
    //abcl_LifeInsuranceLogo = `${ABCL_LOBHoldings}/ABCL_Lifeinsurance.jpg`;
    //abcl_homeLoanLogo = `${ABCL_LOBHoldings}/ABCL_Homeloan.jpg`;
    //abcl_securitiesLogo = `${ABCL_LOBHoldings}/ABCL_Stocks.jpg`;
    //abcl_DigitalLogo = `${ABCL_LOBHoldings}/ABCL_Digital.jpg`;
    //png
    abcl_FinanceLogo = `${ABCL_LOBHoldings}/ABCL_Finance.png`;
    abcl_healthInsuranceLogo = `${ABCL_LOBHoldings}/ABCL_Healthinsurance.png`;
    abcl_AMC = `${ABCL_LOBHoldings}/ABCL_MutualFunds.png`;
    abcl_LifeInsuranceLogo = `${ABCL_LOBHoldings}/ABCL_Lifeinsurance.png`;
    abcl_homeLoanLogo = `${ABCL_LOBHoldings}/ABCL_Homeloan.png`;
    abcl_securitiesLogo = `${ABCL_LOBHoldings}/ABCL_Stocks.png`;
    abcl_DigitalLogo = `${ABCL_LOBHoldings}/ABCL_Digital.png`;
    connectedCallback() {
        //Get assets and set the flags
        this.hasFinanceAssets = true;
        this.hasHealthInsurance = true;
        this.hasHomeLoan = true;
        this.hasLifeInsurance = true;
        this.hasMutualFunds = true;
        this.hasSecurities = true;
        this.hasDigital = true;
    }
}