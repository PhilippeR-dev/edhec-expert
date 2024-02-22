###### Installation de Streamlit

Prérepris :

1. Installation de python (sur PC Windows)

   * https://www.anaconda.com/download
   * https://docs.anaconda.com/free/anaconda/install/windows/
   * ***!!!!! Effectuer cette installation avec un Terminal et le profil utilisateur Administrator !!!!***
2. Création d'un environnement

   ```
   conda create -n py310 python=3.10.9
   ```
3. Activer cet environnement (sur PC Windows)

   ```
   c:\Repos\edhec-expert>c:\apps\Anaconda\Scripts\activate.bat
   ```

   Option : Afficher les informations sur l'installation de Python `conda info`

Installation :

* streamlit

```
conda install conda-forge::streamlit
```

* streamlit-extras

```
(base) c:\Repos\edhec-expert>C:\apps\Anaconda\python.exe -m pip install streamlit-extras
```

###### Exécution du programme

```
(base) C:\Repos\edhec-expert>streamlit run c:\Repos\edhec-expert\ref-geographique\streamlit-app\ref_geographique_analysis.py
```
