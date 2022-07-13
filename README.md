# Polytope XIa

see *developer blog* at https://digitalmediabremen.github.io/PolytopeXIa/

## how to convert a java sketches to processing

navigate to sketch folder ( i.e `./PolytopeXIa/sketches` ) and run shell script `convert-java-to-processing.sh` with the first argument pointing to the java sketch source file:

```
./convert-java-to-processing.sh ../src/de/hfkbremen/polytopexia/sketches/LaserBeamLogo.java
```

note that you might need to manually add libraries in the processing editor ( e.g `import teilchen.*;` ).