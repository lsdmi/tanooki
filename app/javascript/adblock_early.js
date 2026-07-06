import { syncAdblockDocumentClass } from "adblock_detect"

document.addEventListener("DOMContentLoaded", syncAdblockDocumentClass)
document.addEventListener("turbo:load", syncAdblockDocumentClass)
document.addEventListener("turbo:morph", syncAdblockDocumentClass)
