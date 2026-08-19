Write-Host ""
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "  🧹 NETTOYAGE COMPLET DE LA BASE DE DONNEES FIREBASE" -ForegroundColor Yellow
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host " Projet cible : my-dairy-2f7e2" -ForegroundColor White
Write-Host " Action       : Suppression de TOUTES les collections et documents" -ForegroundColor White
Write-Host "                (users, mood_entries, pairing_codes, partner_connections, etc.)" -ForegroundColor Gray
Write-Host ""
Write-Host " ⚠️ ATTENTION : Cette action est IRREVERSIBLE !" -ForegroundColor Red
Write-Host ""

$confirmation = Read-Host "Es-tu sur de vouloir tout supprimer ? (o/N)"
if ($confirmation -notmatch "^(o|oui|y|yes)$") {
    Write-Host "
❌ Operation annulee. Aucune donnee n'a ete supprimee.
" -ForegroundColor Yellow
    exit 0
}

Write-Host "
⏳ Suppression en cours de toutes les donnees Firestore...
" -ForegroundColor Cyan

npx firebase firestore:delete --all-collections --force --project my-dairy-2f7e2

if ($LASTEXITCODE -eq 0) {
    Write-Host "
========================================================" -ForegroundColor Green
    Write-Host " ✅ Base Firestore nettoyee avec succes ! Tout est propre." -ForegroundColor Green
    Write-Host "========================================================
" -ForegroundColor Green
} else {
    Write-Host "
❌ Une erreur est survenue lors de la suppression.
" -ForegroundColor Red
}
