# coding=utf-8

""" MNIST-M dataset. 
    MNIST blended over patches randomly extracted from color photos from BSDS500
"""

from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

from PIL import Image
import numpy as np
import os
import tensorflow.compat.v2 as tf

import tensorflow_datasets.public_api as tfds

URL = "https://arxiv.org/abs/1505.07818"

CITATION = r"""@misc{ganin2015domainadversarial,
    title={Domain-Adversarial Training of Neural Networks},
    author={Yaroslav Ganin and Evgeniya Ustinova and Hana Ajakan and Pascal Germain and Hugo Larochelle and François Laviolette and Mario Marchand and Victor Lempitsky},
    year={2015},
    eprint={1505.07818},
    archivePrefix={arXiv},
    primaryClass={stat.ML}
}"""

DESCRIPTION = (
    "The MNIST-M Dataset an image digit "
    "recognition dataset generated by blending "
    "the MNIST dataset over patches randomly "
    "extracted from color photos from BSDS500."
)


class MnistM(tfds.core.GeneratorBasedBuilder):
    """ MNIST-M dataset. 
        MNIST blended over patches randomly extracted from color photos from BSDS500
    """

    VERSION = tfds.core.Version("0.1.0")

    MANUAL_DOWNLOAD_INSTRUCTIONS = (
        "Please run ./scripts/get_digits.sh to download the MNIST-M dataset. "
    )

    def _info(self):
        return tfds.core.DatasetInfo(
            builder=self,
            description=DESCRIPTION,
            features=tfds.features.FeaturesDict({
                "image": tfds.features.Image(shape=(32, 32, 3)),
                "label": tfds.features.ClassLabel(num_classes=10),
            }),
            supervised_keys=("image", "label"),
            homepage=URL,
            citation=CITATION,
        )

    def _split_generators(self, dl_manager):

        extracted_path = dl_manager.manual_dir

        # Specify the splits
        return [
            tfds.core.SplitGenerator(
                name=tfds.Split.TRAIN,
                gen_kwargs={ #type: ignore
                    "images_dir_path": os.path.join(extracted_path, "mnist_m_train"),
                    "labels_path": os.path.join(extracted_path, "mnist_m_train_labels.txt"),
                },
            ),
            tfds.core.SplitGenerator(
                name=tfds.Split.TEST,
                gen_kwargs={
                    "images_dir_path": os.path.join(extracted_path, "mnist_m_test"),
                    "labels_path": os.path.join(extracted_path, "mnist_m_test_labels.txt"),
                },
            ),
        ]

    def _generate_examples(self, images_dir_path:str , labels_path:str):
        """Generate examples as dicts.
        Args:
        filepath: `str` path of the file to process.
        Yields:
        Generator yielding the next samples
        """

        # the labels file consists of lines of image-names and label pairs, e.g. "00000001.png 2"
        with tf.io.gfile.GFile(labels_path, "rb") as f: # type: ignore
            lines = list(map(
                lambda l: str(l,"utf-8").split(),
                f.readlines()
            ))

        for i, (image_name, label) in enumerate(lines):
            image_path = os.path.join(images_dir_path, image_name)
            image = np.array(Image.open(image_path))
            record = {
                "image": image,
                "label": label,
            }
            yield i, record


if __name__ == "__main__":
    # tf.compat.v1.enable_eager_execution() 
    mnist_m_ds, mnist_m_info = tfds.load("mnist_m", split="train", with_info=True)
    print(mnist_m_info)