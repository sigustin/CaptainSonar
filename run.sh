## Make and execute script

# Compile files
echo "============ Compiling Input.oz ===============" && \
ozc -c Input.oz && \
echo "============ Compiling PlayerManager.oz ===============" && \
ozc -c PlayerManager.oz && \

echo "============ Compiling Player000RandomAI.oz ===============" && \
ozc -c Player000RandomAI.oz && \
echo "============ Compiling Player000BasicAI.oz ================" && \
ozc -c Player000BasicAI.oz && \
#echo "============ Compiling Player000Basic.oz ===============" && \
#ozc -c Player000Basic.oz && \
#echo "============ Compiling Player000BasicRandom.oz ===============" && \
#ozc -c Player000BasicRandom.oz && \

echo "============ Compiling GUI.oz ===============" && \
ozc -c GUI.oz && \

echo "============ Compiling Main.oz ===============" && \
ozc -c Main.oz && \

# Execute program
echo "============ Executing program ===============" && \
ozengine Main.ozf
