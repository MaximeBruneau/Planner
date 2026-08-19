@echo off
chcp 65001 >nul
echo.
echo ========================================================
echo   🧹 NETTOYAGE COMPLET DE LA BASE DE DONNEES FIREBASE
echo ========================================================
echo.
echo  Projet cible : my-dairy-2f7e2
echo  Action       : Suppression de TOUTES les collections et documents
echo                 (users, mood_entries, pairing_codes, partner_connections, etc.)
echo.
echo  ⚠️ ATTENTION : Cette action est IRREVERSIBLE !
echo.

set /p CONFIRM="Es-tu sur de vouloir tout supprimer ? (o/N) : "
if /i "%CONFIRM%" neq "o" if /i "%CONFIRM%" neq "oui" if /i "%CONFIRM%" neq "y" if /i "%CONFIRM%" neq "yes" (
    echo.
    echo ❌ Operation annulee. Aucune donnee n'a ete supprimee.
    echo.
    pause
    exit /b 0
)

echo.
echo ⏳ Suppression en cours de toutes les donnees Firestore...
echo.

call npx firebase firestore:delete --all-collections --force --project my-dairy-2f7e2

if %ERRORLEVEL% equ 0 (
    echo.
    echo ========================================================
    echo  ✅ Base Firestore nettoyee avec succes ! Tout est propre.
    echo ========================================================
    echo.
) else (
    echo.
    echo ❌ Une erreur est survenue lors de la suppression.
    echo.
)

pause
