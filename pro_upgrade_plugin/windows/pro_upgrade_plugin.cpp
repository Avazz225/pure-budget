#include "pro_upgrade_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Services.Store.h>

#include <windows.h>
#include <winrt/base.h> 
#include <iostream>
#include <string>
#include <future>

using namespace winrt;
using namespace Windows::Services::Store;
using namespace winrt::Windows::Foundation::Collections;

using flutter::EncodableValue;
using flutter::MethodChannel;
using flutter::MethodCall;
using flutter::MethodResult;

namespace pro_upgrade_plugin {

ProUpgradePlugin::ProUpgradePlugin() = default;
ProUpgradePlugin::~ProUpgradePlugin() = default;

bool EnsureApartmentInitialized()
{
    APTTYPE aptType;
    APTTYPEQUALIFIER aptQualifier;
    HRESULT hr = CoGetApartmentType(&aptType, &aptQualifier);

    if (hr == S_OK) {
        // Apartment ist bereits initialisiert
        OutputDebugString(L"init_apartment already executed");
        return true;
    } else if (hr == RPC_E_CALL_COMPLETE) {
        // Apartment ist nicht initialisiert -> init_apartment versuchen
        try {
            winrt::init_apartment(winrt::apartment_type::single_threaded);
            return true;
        } catch (const winrt::hresult& e) {
            OutputDebugString(L"init_apartment failed:\n");
            std::wstring s = std::to_wstring(e);
            OutputDebugString(s.c_str());
            return false;
        }
    } else {
        // Anderer Fehler beim Abfragen der Apartment-Art
        OutputDebugString(L"CoGetApartmentType failed\n");
        return false;
    }
}

static bool IsProPurchasedFromStore(const std::wstring& storeAddOnId) {
    std::promise<bool> resultPromise;
    auto resultFuture = resultPromise.get_future();

    std::thread staThread([storeAddOnId, &resultPromise]() {
        OutputDebugString(L"IsProPurchasedFromStore called\n");

        if (!EnsureApartmentInitialized()) {
            resultPromise.set_value(false);
            return;
        }

        StoreContext context = StoreContext::GetDefault();
        OutputDebugString(L"Got StoreContext\n");

        auto licenseOp = context.GetAppLicenseAsync();
        auto license = licenseOp.get();

        OutputDebugString(L"Got AppLicense\n");

        auto addOnLicenses = license.AddOnLicenses();

        if (!addOnLicenses.HasKey(storeAddOnId)) {
            OutputDebugString(L"storeAddOnId not found in licenses\n");
            resultPromise.set_value(false);
            return;
        }

        auto it = addOnLicenses.Lookup(storeAddOnId);
        if (it) {
            OutputDebugString(L"License found, checking if active\n");
            bool active = it.IsActive();
            OutputDebugString(active ? L"License is active\n" : L"License is NOT active\n");
            resultPromise.set_value(active);
            return;
        }

        OutputDebugString(L"License lookup failed\n");
        resultPromise.set_value(false);
    });
    staThread.join();
    return resultFuture.get();
}

static void OpenPurchaseLink(const std::wstring& url) {
    ShellExecuteW(nullptr, L"open", url.c_str(), nullptr, nullptr, SW_SHOWNORMAL);
}

void ProUpgradePlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {

    auto channel = std::make_unique<MethodChannel<EncodableValue>>(
        registrar->messenger(), "pro_upgrade_plugin",
        &flutter::StandardMethodCodec::GetInstance());

    channel->SetMethodCallHandler(
        [](const MethodCall<EncodableValue>& call,
            std::unique_ptr<MethodResult<EncodableValue>> result) {
            if (call.method_name().compare("checkProUpgrade") == 0) {
                const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());

                std::string purchaseUrl;
                std::string productId;

                if (args) {
                    auto itUrl = args->find(flutter::EncodableValue("purchaseUrl"));
                    if (itUrl != args->end() && std::holds_alternative<std::string>(itUrl->second)) {
                        purchaseUrl = std::get<std::string>(itUrl->second);
                    }

                    auto itId = args->find(flutter::EncodableValue("productId"));
                    if (itId != args->end() && std::holds_alternative<std::string>(itId->second)) {
                        productId = std::get<std::string>(itId->second);
                    }
                }

                // Konvertiere productId (UTF-8) zu std::wstring
                std::wstring wproductId(productId.begin(), productId.end());

                bool purchased = IsProPurchasedFromStore(wproductId);
                if (!purchased && !purchaseUrl.empty()) {
                    std::wstring wurl(purchaseUrl.begin(), purchaseUrl.end());
                    OpenPurchaseLink(wurl);
                }
                result->Success(EncodableValue(purchased));
            } else {
                result->NotImplemented();
            }
        });

    registrar->AddPlugin(std::make_unique<ProUpgradePlugin>());
}

}  // namespace pro_upgrade_plugin
