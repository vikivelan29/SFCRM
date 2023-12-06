import { LightningElement } from "lwc";
import { registerRefreshHandler, unregisterRefreshHandler } from "lightning/refresh";

export default class Asf_RefreshHandler extends LightningElement {
    refreshHandlerID;
    connectedCallback() {
        this.refreshHandlerID = registerRefreshHandler(this, this.refreshHandler);
        // if the component runs in an org with Lightning Locker instead of LWS, use
        // this.refreshHandlerID = registerRefreshHandler(this.template.host, this.refreshHandler.bind(this));
    }
    disconnectedCallback() {
        unregisterRefreshHandler(this.refreshHandlerID);
    }
    refreshHandler() {
        // example usage case for refresh participant
        return new Promise((resolve) => {
        resolve(true);
        });
    }
}