""" testing code """
import torch
from argparse import ArgumentParser

try:
    from . import utils
    from . import inference
    from . import encode as enc
except ImportError:
    import utils
    import inference
    import encode as enc

def load_checkpoint_run_inference(checkpoint_path, variants, dataset):
    """ loads a finetuned 3D model from a checkpoint and scores variants with the model """

    # the Lightning checkpoint from the finetuning we performed above
    model = inference.load_pytorch_module(checkpoint_path)

    # load the wild-type sequence and the PDB file (needed for 3D RPE) for the dataset
    datasets = utils.load_dataset_metadata()
    wt = datasets[dataset]["wt_aa"]
    wt_offset = datasets[dataset]["wt_ofs"]
    pdb_fn = datasets[dataset]["pdb_fn"]

    variants = variants.split("_")

    encoded_variants = enc.encode(
        encoding="int_seqs",
        variants=variants,
        wt_aa=wt,
        wt_offset=wt_offset,
        indexing="0_indexed"
    )

    # set model to eval mode
    model.eval()

    # no need to compute gradients for inference
    with torch.no_grad():
        # note we are specifying the pdb_fn because this model uses 3D RPE
        predictions = model(torch.tensor(encoded_variants), pdb_fn=pdb_fn)

    print(predictions)


if __name__ == "__main__":
    parser = ArgumentParser(add_help=True)

    parser.add_argument("--ckpt_path",
                        help="path to saved METL target model",
                        type=str)
    parser.add_argument("--variants",
                        help="underscore-separated list of variants to score",
                        type=str)
    parser.add_argument("--dataset",
                        help="protein dataset to load to obtain sequence and structure",
                        type=str)

    parsed_args = parser.parse_args()

    load_checkpoint_run_inference(parsed_args.ckpt_path, parsed_args.variants, parsed_args.dataset)
