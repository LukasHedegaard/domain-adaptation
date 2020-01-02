#!/usr/bin/env bash
DESCRIPTION="Multitask training. 
Here, we use the weights from source tuning as a starting point."

METHOD=multitask
GPU_ID=0
OPTIMIZER=adam
ARCHITECTURE=two_stream_pair_embeds
MODEL_BASE=vgg16
FEATURES=images
BATCH_SIZE=16
AUGMENT=0
EXPERIMENT_ID_BASE="${MODEL_BASE}_grad"

for LEARNING_RATE in 1e-5 #1e-6 1e-7
do
    for SEED in 0 #1 #2 3 4 
    do
        for SOURCE in D #A D W
        do
            for TARGET in A #A D W
            do
                if [ $SOURCE != $TARGET ]
                then
                    FE_RUN_DIR="./runs/tune_source/${MODEL_BASE}_aug_ft_best/${SOURCE}${TARGET}"
                    FROM_WEIGHTS="${FE_RUN_DIR}/checkpoints/cp-best.ckpt"

                    EXPERIMENT_ID="${EXPERIMENT_ID_BASE}"
                    DIR_NAME=./runs/$METHOD/$EXPERIMENT_ID
                    mkdir $DIR_NAME -p
                    echo $DESCRIPTION > $DIR_NAME/description.txt

                    TIMESTAMP_OLD=$(date '+%Y%m%d%H%M%S')

                    python3 run.py \
                        --num_unfrozen_base_layers 0 \
                        --training_regimen  regular \
                        --timestamp         $TIMESTAMP_OLD \
                        --learning_rate     $LEARNING_RATE \
                        --epochs            15 \
                        --gpu_id            $GPU_ID \
                        --optimizer         $OPTIMIZER \
                        --experiment_id     $EXPERIMENT_ID \
                        --source            $SOURCE \
                        --target            $TARGET \
                        --seed              $SEED \
                        --method            $METHOD \
                        --architecture      $ARCHITECTURE \
                        --model_base        $MODEL_BASE \
                        --features          $FEATURES \
                        --batch_size        $BATCH_SIZE \
                        --augment           $AUGMENT \
                        --from_weights      $FROM_WEIGHTS \
                        # --num_unfrozen_base_layers 12 \

                    # RUN_DIR=./runs/$METHOD/$EXPERIMENT_ID/${SOURCE}${TARGET}_${SEED}_${TIMESTAMP}

                    # for FROM_WEIGHTS_DIR in ./runs/$METHOD/$EXPERIMENT_ID/${SOURCE}${TARGET}_${SEED}*
                    # do
                    #     FROM_WEIGHTS=$FROM_WEIGHTS_DIR/checkpoints/cp-best.ckpt
                    #     echo "Found ${FROM_WEIGHTS}"
                    
                    FROM_WEIGHTS="./runs/$METHOD/$EXPERIMENT_ID/${SOURCE}${TARGET}_${SEED}_${TIMESTAMP_OLD}/checkpoints/cp-best.ckpt"
                    EXPERIMENT_ID="${EXPERIMENT_ID_BASE}_coarse_grad_ft"
                    DIR_NAME=./runs/$METHOD/$EXPERIMENT_ID
                    mkdir $DIR_NAME -p
                    echo $DESCRIPTION > $DIR_NAME/description.txt

                    TIMESTAMP=$(date '+%Y%m%d%H%M%S')

                    python3 run.py \
                        --training_regimen  gradual_unfreeze \
                        --learning_rate     1e-5 \
                        --epochs            10 \
                        --optimizer         $OPTIMIZER \
                        --gpu_id            $GPU_ID \
                        --experiment_id     $EXPERIMENT_ID \
                        --source            $SOURCE \
                        --target            $TARGET \
                        --seed              $SEED \
                        --method            $METHOD \
                        --architecture      $ARCHITECTURE \
                        --model_base        $MODEL_BASE \
                        --features          $FEATURES \
                        --batch_size        $BATCH_SIZE \
                        --augment           $AUGMENT \
                        --from_weights      $FROM_WEIGHTS \
                        --timestamp         $TIMESTAMP \

                    # RUN_DIR=./runs/$METHOD/$EXPERIMENT_ID/${SOURCE}${TARGET}_${SEED}_${TIMESTAMP}

                    # if [ ! -f "$RUN_DIR/report.json" ]; then
                    #     rm -rf $RUN_DIR
                    # else
                    #     rm -rf $RUN_DIR/checkpoints
                    #     rm -rf $FE_RUN_DIR/checkpoints
                    # fi

                    #     break
                    # done
                fi
            done
        done
    done
done

./scripts/notify.sh "Finished job: ${METHOD}/${EXPERIMENT_ID_BASE} on GPU ${GPU_ID}."